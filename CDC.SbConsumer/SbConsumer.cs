using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;

namespace CDC.SbConsumer
{
    public class SbConsumer
    {
        [FunctionName("SbConsumer")]
        public void Run([ServiceBusTrigger("%QueueName%", Connection = "ServiceBusHostName", IsSessionsEnabled = true)]string myQueueItem, ILogger log)
        {
            log.LogInformation($"C# ServiceBus queue trigger function processed message: {myQueueItem}");
        }
    }
}
