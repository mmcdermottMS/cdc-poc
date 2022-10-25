using CDC.Domain;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;

namespace CDC.EhProducer
{
    public class ProduceEvents
    {
        private readonly HttpClient _httpClient;

        public ProduceEvents()
        {
            _httpClient = new HttpClient
            {
                BaseAddress = new Uri(Environment.GetEnvironmentVariable("BaseWeatherUri"))
            };
        }

        [FunctionName("ProduceEvents")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequest req, ILogger log)
        {
            var result = await _httpClient.GetFromJsonAsync<List<WeatherForecast>>("WeatherForecast");

            if (!int.TryParse(req.Query["messageCount"], out int messageCount))
            {
                messageCount = 1;
            }
            if(messageCount < 1)
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

            try
            {
                var producer = new Producer(log);

                var sw = Stopwatch.StartNew();
                await CosmosInitializer.Initalize();
                await producer.PublishMessages(messageCount, cycles, delayMs);

                return new OkObjectResult($"Produced {messageCount} messages in {cycles} cycles in {sw.ElapsedMilliseconds}ms.  With Weather");
            }
            catch (Exception ex)
            {
                return new OkObjectResult(ex.Message);
            }
        }
    }
}
