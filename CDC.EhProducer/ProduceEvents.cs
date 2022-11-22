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
    public class ProduceEvents
    {
        private readonly IProducer _producer;

        public ProduceEvents(IProducer producer)
        {
            _producer = producer;
        }

        [FunctionName("ProduceEvents")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequest req, ILogger log)
        {

            if (!int.TryParse(req.Query["messageCount"], out int messageCount))
            {
                messageCount = 1;
            }
            if (messageCount < 1)
            {
                messageCount = 1;
            }

            if (!int.TryParse(req.Query["numCycles"], out int cycles))
            {
                cycles = 1;
            }

            if (!int.TryParse(req.Query["delayMs"], out int delayMs))
            {
                delayMs = 0;
            }

            if (!int.TryParse(req.Query["partitionCount"], out int partitionCount))
            {
                partitionCount = 1;
            }

            try
            {
                var sw = Stopwatch.StartNew();
                await CosmosInitializer.Initalize();
                _producer.Log = log;
                await _producer.PublishMessages(messageCount, cycles, delayMs, partitionCount);
                return new OkObjectResult($"Produced {messageCount} messages in {cycles} cycles in {sw.ElapsedMilliseconds}ms.");
            }
            catch (Exception ex)
            {
                return new OkObjectResult(ex.Message);
            }
        }
    }
}
