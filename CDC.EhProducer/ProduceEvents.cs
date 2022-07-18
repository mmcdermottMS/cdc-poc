using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using System;
using System.Diagnostics;
using System.Threading.Tasks;

namespace CDC.EhProducer
{
    public static class ProduceEvents
    {
        [FunctionName("ProduceEvents")]
        public static async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequest req, ILogger log)
        {
            if (!int.TryParse(req.Query["messageCount"], out int messageCount) || !int.TryParse(req.Query["partitionCount"], out int partitionCount))
            {
                return new OkObjectResult("Must specify message count and partition count");
            }

            if (!int.TryParse(req.Query["numCycles"], out int cycles))
            {
                cycles = 1;
            }

            if (!int.TryParse(req.Query["delayMs"], out int delayMs))
            {
                delayMs = 0;
            }

            try
            {
                var producer = new Producer(log);

                var sw = Stopwatch.StartNew();
                await CosmosInitializer.Initalize();
                await producer.PublishMessages(messageCount, partitionCount, cycles, delayMs);

                return new OkObjectResult($"Produced {messageCount} messages in {cycles} cycles across {partitionCount} partitions in {sw.ElapsedMilliseconds}ms");
            }
            catch (Exception ex)
            {
                return new OkObjectResult(ex.Message);
            }
        }
    }
}
