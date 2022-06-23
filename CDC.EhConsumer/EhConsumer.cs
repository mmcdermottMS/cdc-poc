using Azure.Identity;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Azure.Messaging.ServiceBus;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace CDC
{
    public static class EhConsumer
    {
        private static readonly ServiceBusClient _serviceBusClient = new ServiceBusClient(Environment.GetEnvironmentVariable("ServiceBusHostName"), new DefaultAzureCredential());
        private static readonly ServiceBusSender _sender = _serviceBusClient.CreateSender(Environment.GetEnvironmentVariable("QueueName"));

        [FunctionName("EhConsumer")]
        public static async Task Run([EventHubTrigger("%EhName%", Connection = "EhNameSpace")] EventData[] events, ILogger log, PartitionContext partitionContext)
        {
            var exceptions = new List<Exception>();

            var messageBatch = await _sender.CreateMessageBatchAsync();
            foreach (EventData eventData in events)
            {
                //TODO: Deserialize against Azure Schema Registry Here

                try
                {
                    var message = new ServiceBusMessage(eventData.EventBody) { SessionId = partitionContext.PartitionId };

                    if (!messageBatch.TryAddMessage(message))
                    {
                        await _sender.SendMessagesAsync(messageBatch);
                        messageBatch = await _sender.CreateMessageBatchAsync();

                        if (!messageBatch.TryAddMessage(message))
                        {
                            throw new Exception("Address is too big for a new message batch");
                        }
                    }

                    await _sender.SendMessagesAsync(messageBatch);
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
