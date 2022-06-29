using Azure.Identity;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Azure.Messaging.ServiceBus;
using Microsoft.ApplicationInsights;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;

namespace CDC
{
    public class EhConsumer
    {
        private readonly TelemetryClient _telemetryClient;
        private readonly ServiceBusClient _serviceBusClient;
        private readonly Lazy<ServiceBusSender> _serviceBusSenderLazy;

        public EhConsumer(TelemetryClient telemetryClient, ServiceBusClient serviceBusClient)
        {
            _telemetryClient = telemetryClient;
            _serviceBusClient = serviceBusClient;
            _serviceBusSenderLazy = new Lazy<ServiceBusSender>(_serviceBusClient.CreateSender(Environment.GetEnvironmentVariable("QueueName")));
        }

        [FunctionName("EhConsumer")]
        public async Task Run([EventHubTrigger("%EhName%", Connection = "EhNameSpace")] EventData[] events, ILogger log, PartitionContext partitionContext)
        {
            var serviceBusSender = _serviceBusSenderLazy.Value;
            _telemetryClient.TrackMetric("inboundEventBatchSize", events.Length);
            var exceptions = new List<Exception>();

            try
            {
                var sw = Stopwatch.StartNew();
                var messageBatch = await serviceBusSender.CreateMessageBatchAsync();
                foreach (EventData eventData in events)
                {
                    //TODO: Deserialize against Azure Schema Registry Here
                    var message = new ServiceBusMessage(eventData.EventBody) { SessionId = partitionContext.PartitionId };

                    if (!messageBatch.TryAddMessage(message))
                    {
                        await serviceBusSender.SendMessagesAsync(messageBatch);
                        messageBatch = await serviceBusSender.CreateMessageBatchAsync();

                        if (!messageBatch.TryAddMessage(message))
                        {
                            throw new Exception("Event is too big for a new message batch");
                        }
                    }
                }
                await serviceBusSender.SendMessagesAsync(messageBatch);

                log.LogInformation($"Processed {events.Length} events for partition ID {partitionContext.PartitionId} in {sw.ElapsedMilliseconds}ms");
            }
            catch (Exception e)
            {
                // We need to keep processing the rest of the batch - capture this exception and continue.
                // Also, consider capturing details of the message that failed processing so it can be processed again later.
                exceptions.Add(e);
            }

            // Once processing of the batch is complete, if any messages in the batch failed processing throw an exception so that there is a record of the failure.

            if (exceptions.Count > 1)
                throw new AggregateException(exceptions);

            if (exceptions.Count == 1)
                throw exceptions.Single();
        }
    }
}
