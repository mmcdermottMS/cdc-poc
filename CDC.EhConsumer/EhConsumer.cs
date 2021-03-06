using Azure.Identity;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Azure.Messaging.ServiceBus;
using CDC.Domain;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;

namespace CDC.EhConsumer
{
    public static class EhConsumer
    {
        //TODO: move SB Host Name into config
        private static readonly ServiceBusClient _serviceBusClient = new("cdc-poc-wus-sbns-01.servicebus.windows.net", new DefaultAzureCredential());
        private static readonly ServiceBusSender _serviceBusSender = _serviceBusClient.CreateSender("addresses");

        [FunctionName("EhConsumer")]
        public static async Task Run([EventHubTrigger("addresses", Connection = "EhNameSpace")] EventData[] events, ILogger log, PartitionContext partitionContext)
        {
            log.LogInformation($"Received {events.Length} events for partition ID {partitionContext.PartitionId}");

            var exceptions = new List<Exception>();

            try
            {
                var sw = Stopwatch.StartNew();
                var messageBatch = await _serviceBusSender.CreateMessageBatchAsync();
                foreach (EventData eventData in events)
                {
                    //TODO: Deserialize against Azure Schema Registry Here
                    var sourceAddress = JsonConvert.DeserializeObject<SourceAddress>(eventData.EventBody.ToString());
                    var sessionId = sourceAddress.ProfileId.ToString();
                    
                    var message = new ServiceBusMessage(eventData.EventBody) { SessionId = sessionId };

                    if (!messageBatch.TryAddMessage(message))
                    {
                        await _serviceBusSender.SendMessagesAsync(messageBatch);
                        messageBatch = await _serviceBusSender.CreateMessageBatchAsync();

                        if (!messageBatch.TryAddMessage(message))
                        {
                            throw new Exception("Event is too big for a new message batch");
                        }
                    }
                }
                await _serviceBusSender.SendMessagesAsync(messageBatch);

                log.LogInformation($"Processed {events.Length} events in {sw.ElapsedMilliseconds}ms");
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
