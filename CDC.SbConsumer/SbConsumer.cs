using Azure.Messaging.ServiceBus;
using CDC.Domain;
using CDC.Domain.Interfaces;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.ServiceBus;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading;
using System.Threading.Tasks;

namespace CDC.SbConsumer
{
    public class SbConsumer
    {
        private readonly ICosmosDbService _cosmosDbService;
        private readonly Random _random;
        private readonly HttpClient _httpClient;

        public SbConsumer(ICosmosDbService cosmosDbService)
        {
            _cosmosDbService = cosmosDbService;
            _random = new Random();
            _httpClient = new HttpClient
            {
                BaseAddress = new Uri(Environment.GetEnvironmentVariable("ExternalApiUri"))
            };
        }

        [FunctionName("SbConsumer")]
        public async Task Run([ServiceBusTrigger("%QueueName%", Connection = "ServiceBusConnection", IsSessionsEnabled = true)]
            ServiceBusReceivedMessage message,
            ServiceBusMessageActions messageActions,
            ILogger log)
        {

            var result = await _httpClient.GetFromJsonAsync<List<WeatherForecast>>("WeatherForecast");

            try
            {
                log.LogInformation($"Processed Profile ID: {message.SessionId}");

                var sourceAddress = JsonConvert.DeserializeObject<MongoAddress>(JsonConvert.DeserializeObject<ConnectWrapper>(message.Body.ToString()).Payload);
                var targetAddress = await _cosmosDbService.GetTargetAddressByProfileIdAsync(sourceAddress.ProfileId.Value);

                var zipSplit = sourceAddress.ZipCode.Split("-");
                if (targetAddress == null)
                {
                    targetAddress = new TargetAddress()
                    {
                        Id = Guid.NewGuid().ToString(),
                        ProfileId = sourceAddress.ProfileId.Value,
                        Street1 = sourceAddress.Street1,
                        Street2 = $"{sourceAddress.Street2} - {sourceAddress.Street3}",
                        City = sourceAddress.City,
                        State = sourceAddress.State,
                        Zip = zipSplit.Length > 1 ? sourceAddress.ZipCode.Split("-")[0] : sourceAddress.ZipCode,
                        ZipExtension = zipSplit.Length > 1 ? sourceAddress.ZipCode.Split("-")[1] : string.Empty,
                        CreatedDateUtc = new DateTime().AddMilliseconds(sourceAddress.CreatedDateUtc.Value)
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
                    targetAddress.UpdatedDateUtc = sourceAddress.UpdatedDateUtc != null ? new DateTime().AddMilliseconds(sourceAddress.UpdatedDateUtc.Value) : DateTime.UtcNow;
                    targetAddress.LatencyMs = (DateTime.UtcNow - targetAddress.UpdatedDateUtc).Milliseconds;
                }

                await _cosmosDbService.UpsertTargetAddress(targetAddress);
                log.LogInformation($"Upserted Address");

                //Simulate additional processing time above and beyond the basic ETL being done above
                Thread.Sleep(_random.Next(250, 750));

                await messageActions.CompleteMessageAsync(message);

                /*
                if (DateTime.UtcNow.Millisecond > 990)
                {
                    throw new Exception("Random Exception from SbConsumer");
                }
                */

                var totalProcessingTime = (DateTime.UtcNow - targetAddress.CreatedDateUtc).Duration().TotalMilliseconds;
                log.LogInformation($"Total processing time: {totalProcessingTime}");
            }
            //TODO: https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-exceptions
            //TODO: Optimize these calls to elminate the repeated code
            catch (ServiceBusException ex)
            {
                await messageActions.AbandonMessageAsync(message);
                log.LogError(ex, $"Service Bus Exception when consuming message from topic {Environment.GetEnvironmentVariable("SubscriberName")} for subscriber {Environment.GetEnvironmentVariable("SubscriberName")}");

            }
            catch (CosmosException ex)
            {
                await messageActions.AbandonMessageAsync(message);
                log.LogError(ex, $"Cosmos Exception when consuming message from topic {Environment.GetEnvironmentVariable("SubscriberName")} for subscriber {Environment.GetEnvironmentVariable("SubscriberName")}");
            }
            catch (Exception ex)
            {
                await messageActions.AbandonMessageAsync(message);
                log.LogError(ex, $"Unknown Exception consuming message from topic {Environment.GetEnvironmentVariable("SubscriberName")} for subscriber {Environment.GetEnvironmentVariable("SubscriberName")}");

                throw;
            }
        }
    }
}
