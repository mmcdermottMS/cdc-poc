using Azure.Messaging.ServiceBus;
using CDC.Domain;
using CDC.Domain.Interfaces;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.ServiceBus;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;

namespace CDC.SbConsumer
{
    public class SbConsumer
    {
        private readonly TelemetryClient _telemetryClient;
        private readonly ICosmosDbService _cosmosDbService;
        private readonly Random _random;

        public SbConsumer(TelemetryClient telemetryClient, ICosmosDbService cosmosDbService)
        {
            _telemetryClient = telemetryClient;
            _cosmosDbService = cosmosDbService;
            _random = new Random();
        }

        [FunctionName("SbConsumer")]
        public async Task Run([ServiceBusTrigger("%QueueName%", Connection = "ServiceBusConnection", IsSessionsEnabled = true)]
            ServiceBusReceivedMessage message,
            ServiceBusMessageActions messageActions,
            ILogger log)
        {
            message.ApplicationProperties.TryGetValue("Diagnostic-Id", out var objectId);
            string diagnosticId = objectId as string;

            //Create an activity specific to SB message processing.  See list of all
            //available instrumented operations here: https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-end-to-end-tracing?tabs=net-standard-sdk-2#instrumented-operations
            var processMessageActivity = new Activity("ServiceBusProcessor.ProcessMessage");

            //Set the parent Id of the activity to the Diagnostic-Id from the received message.  This will 
            //allow the Diagnostic-Id to propagate through the call chain
            processMessageActivity.SetParentId(diagnosticId);

            //Start a telemetry operation using the newly created activity
            using var processMessageOperation = _telemetryClient.StartOperation<RequestTelemetry>(processMessageActivity);

            try
            {
                log.LogInformation($"Received message for Session ID {message.SessionId}");

                var sourceAddress = JsonConvert.DeserializeObject<SourceAddress>(message.Body.ToString());

                var targetAddress = await _cosmosDbService.GetTargetAddressByProfileIdAsync(sourceAddress.ProfileId.ToString());

                var zipSplit = sourceAddress.ZipCode.Split("-");
                if (targetAddress == null)
                {
                    targetAddress = new TargetAddress()
                    {
                        id = Guid.NewGuid().ToString(),
                        profileId = sourceAddress.ProfileId.ToString(),
                        Street1 = sourceAddress.Street1,
                        Street2 = $"{sourceAddress.Street2} - {sourceAddress.Street3}",
                        City = sourceAddress.City,
                        State = sourceAddress.State,
                        Zip = zipSplit.Length > 1 ? sourceAddress.ZipCode.Split("-")[0] : sourceAddress.ZipCode,
                        ZipExtension = zipSplit.Length > 1 ? sourceAddress.ZipCode.Split("-")[1] : string.Empty,
                        DateCreated = sourceAddress.CreatedDate
                    };
                }
                else
                {
                    targetAddress.Street1 = sourceAddress.Street1;
                    targetAddress.Street2 = $"{sourceAddress.Street2} - {sourceAddress.Street3}";
                    targetAddress.City = sourceAddress.City;
                    targetAddress.State = sourceAddress.State;
                    targetAddress.Zip = zipSplit.Length > 1 ? sourceAddress.ZipCode.Split("-")[0] : sourceAddress.ZipCode;
                    targetAddress.ZipExtension = zipSplit.Length > 1 ? sourceAddress.ZipCode.Split("-")[1] : string.Empty;
                    targetAddress.DateUpdated = DateTime.UtcNow;
                }

                await _cosmosDbService.UpsertTargetAddress(targetAddress);
                log.LogInformation($"Upserted Address");

                //Simulate additional processing time above and beyond the basic ETL being done above
                Thread.Sleep(_random.Next(250, 750));

                await messageActions.CompleteMessageAsync(message);

                var totalProcessingTime = (DateTime.UtcNow - sourceAddress.CreatedDate).Duration().TotalMilliseconds;
                _telemetryClient.TrackTrace($"Total processing time: {totalProcessingTime}");
            }
            //TODO: https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-exceptions
            //TODO: Optimize these calls to elminate the repeated code
            catch (ServiceBusException ex)
            {
                await messageActions.AbandonMessageAsync(message);
                log.LogError(ex, $"Service Bus Exception when consuming message from topic {Environment.GetEnvironmentVariable("SubscriberName")} for subscriber {Environment.GetEnvironmentVariable("SubscriberName")}");

                //For any given failure, track the exception with the TelemetryClient and set the success flag to false.
                _telemetryClient.TrackException(ex);
                processMessageOperation.Telemetry.Success = false;
            }
            catch (CosmosException ex)
            {
                await messageActions.AbandonMessageAsync(message);
                log.LogError(ex, $"Service Bus Exception when consuming message from topic {Environment.GetEnvironmentVariable("SubscriberName")} for subscriber {Environment.GetEnvironmentVariable("SubscriberName")}");

                //For any given failure, track the exception with the TelemetryClient and set the success flag to false.
                _telemetryClient.TrackException(ex);
                processMessageOperation.Telemetry.Success = false;
            }
            catch (Exception ex)
            {
                await messageActions.AbandonMessageAsync(message);
                log.LogError(ex, $"Unknown Exception consuming message from topic {Environment.GetEnvironmentVariable("SubscriberName")} for subscriber {Environment.GetEnvironmentVariable("SubscriberName")}");

                //For any given failure, track the exception with the TelemetryClient and set the success flag to false.
                _telemetryClient.TrackException(ex);
                processMessageOperation.Telemetry.Success = false;
                processMessageOperation.Telemetry.Stop();
                throw;
            }

            //Stop the teleemetry opration once the function has completed.
            processMessageOperation.Telemetry.Stop();
        }
    }
}
