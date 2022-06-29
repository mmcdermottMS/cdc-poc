using Azure.Messaging.ServiceBus;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.ServiceBus;
using Microsoft.Extensions.Logging;
using System;
using System.Diagnostics;
using System.Threading.Tasks;

namespace CDC.SbConsumer
{
    public class SbConsumer
    {
        private readonly TelemetryClient _telemetryClient;

        public SbConsumer(TelemetryClient telemetryClient)
        {
            _telemetryClient = telemetryClient;
        }

        [FunctionName("SbConsumer")]
        public async Task Run([ServiceBusTrigger("%QueueName%", Connection = "ServiceBusConnection", IsSessionsEnabled = true)]
            ServiceBusReceivedMessage message,
            ServiceBusMessageActions messageActions,
            ILogger log)
        {
            //Grab the existing Diagnostic-Id value from the received message.  The body of this conditional will
            //not execute if the Diagnostic-Id is not a valid string - NFR may dictate a different way of handling that condition
            if (message.ApplicationProperties.TryGetValue("Diagnostic-Id", out var objectId) && objectId is string diagnosticId)
            {
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
                    //TODO - DO WORK HERE, DATA TRANSFORMATION AND WRITE TO COSMOSDB

                    log.LogInformation($"Received message for Session ID {message.SessionId}");
                    await messageActions.CompleteMessageAsync(message);

                    _telemetryClient.TrackTrace($"ServiceBus Listener for Queue '{Environment.GetEnvironmentVariable("QueueName")}' processed message: {message.Body}");
                }
                //TODO: https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-exceptions
                catch (Exception ex)
                {
                    //await messageActions.AbandonMessageAsync(message);
                    log.LogError(ex, $"Error consuming message from topic {Environment.GetEnvironmentVariable("SubscriberName")} for subscriber {Environment.GetEnvironmentVariable("SubscriberName")}");

                    //For any given failure, track the exception with the TelemetryClient and set the success flag to false.
                    _telemetryClient.TrackException(ex);
                    processMessageOperation.Telemetry.Success = false;
                    throw;
                }

                //Stop the teleemetry opration once the function has completed.
                processMessageOperation.Telemetry.Stop();
            }                
        }
    }
}
