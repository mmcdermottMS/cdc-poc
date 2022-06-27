using Azure.Identity;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Azure.Messaging.ServiceBus;
using Microsoft.ApplicationInsights;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace CDC
{
    public class EhConsumer
    {
        private readonly ServiceBusClient _serviceBusClient;
        private readonly ServiceBusSender _serviceBusSender;
        private readonly TelemetryClient _telemetryClient;

        public EhConsumer(TelemetryClient telemetryClient)
        {
            _serviceBusClient = new ServiceBusClient(Environment.GetEnvironmentVariable("ServiceBusHostName"), new DefaultAzureCredential());
            _serviceBusSender = _serviceBusClient.CreateSender(Environment.GetEnvironmentVariable("QueueName"));
            _telemetryClient = telemetryClient;
        }

        [FunctionName("EhConsumer")]
        public async Task Run([EventHubTrigger("%EhName%", Connection = "EhNameSpace")] EventData[] events, ILogger log, PartitionContext partitionContext)
        {
            

            var exceptions = new List<Exception>();

            var messageBatch = await _serviceBusSender.CreateMessageBatchAsync();
            foreach (EventData eventData in events)
            {
                //TODO: Deserialize against Azure Schema Registry Here

                try
                {
                    var message = new ServiceBusMessage(eventData.EventBody) { SessionId = partitionContext.PartitionId };

                    if (!messageBatch.TryAddMessage(message))
                    {
                        await _serviceBusSender.SendMessagesAsync(messageBatch);
                        messageBatch = await _serviceBusSender.CreateMessageBatchAsync();

                        if (!messageBatch.TryAddMessage(message))
                        {
                            throw new Exception("Address is too big for a new message batch");
                        }
                    }

                    await _serviceBusSender.SendMessagesAsync(messageBatch);
                    Console.WriteLine($"Sent {messageBatch.Count} messages to Service Bus session ID {partitionContext.PartitionId}");
                }
                catch (Exception e)
                {
                    // We need to keep processing the rest of the batch - capture this exception and continue.
                    // Also, consider capturing details of the message that failed processing so it can be processed again later.
                    exceptions.Add(e);
                }
            }

            // Once processing of the batch is complete, if any messages in the batch failed processing throw an exception so that there is a record of the failure.

            if (exceptions.Count > 1)
                throw new AggregateException(exceptions);

            if (exceptions.Count == 1)
                throw exceptions.Single();
        }
    }
}
