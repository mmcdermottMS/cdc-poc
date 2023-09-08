using Azure.Messaging.ServiceBus;
using Bogus;
using CDC.Domain;
using CDC.Domain.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.ServiceBus;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Net.Http;
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
            if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("ExternalApiUri")))
            {
                _httpClient = new HttpClient
                {
                    BaseAddress = new Uri(Environment.GetEnvironmentVariable("ExternalApiUri"))
                };
            }
        }

        [FunctionName("SbConsumer")]
        public async Task Run([ServiceBusTrigger("%QueueName%", Connection = "ServiceBusConnection", IsSessionsEnabled = false)]
            ServiceBusReceivedMessage message,
            ServiceBusMessageActions messageActions,
            ILogger log)
        {
            if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("ExternalApiUri")))
            {
                /*
                var results = await _httpClient.GetFromJsonAsync<List<WeatherForecast>>("WeatherForecast");
                foreach (var result in results)
                {
                    log.LogInformation($"Weather Result Summary: {result.Summary}");
                }
                */

                var apiCallResult = await _httpClient.GetAsync(Environment.GetEnvironmentVariable("ExternalApiUri"));
                log.LogInformation($"Successfully made API call to {Environment.GetEnvironmentVariable("ExternalApiUri")}: {apiCallResult.Content}");
            }

            try
            {
                var sw = Stopwatch.StartNew();

                var sourceAddress = JsonConvert.DeserializeObject<Address>(message.Body.ToString());

                var targetAddress = await _cosmosDbService.GetByIdAsync(sourceAddress.Id);
                if (targetAddress == null)
                {
                    targetAddress = sourceAddress;
                }
                else
                {
                    targetAddress.Street1 = sourceAddress.Street1;
                    targetAddress.Street2 = sourceAddress.Street2;
                    targetAddress.City = sourceAddress.City;
                    targetAddress.State = sourceAddress.State;
                    targetAddress.Zip = sourceAddress.Zip;
                    targetAddress.ZipExtension = sourceAddress.ZipExtension;
                    targetAddress.UpdatedDateUtc = sourceAddress.UpdatedDateUtc;
                    targetAddress.LatencyMs = (DateTime.UtcNow - targetAddress.UpdatedDateUtc).TotalMilliseconds;
                }

                await _cosmosDbService.UpsertTargetAddress(targetAddress);
                log.LogInformation($"Upserted Address - Latency in MS: {targetAddress.LatencyMs}");

                //Simulate additional processing time above and beyond the basic ETL being done above
                if (int.TryParse(Environment.GetEnvironmentVariable("ADDITIONAL_SIMULATED_PROC_TIME_MS"), out int simulatedProcessingTime))
                {
                    if (simulatedProcessingTime > 0)
                    {
                        Thread.Sleep(_random.Next(0, simulatedProcessingTime));
                    }
                }

                //Simulate random failures
                if (int.TryParse(Environment.GetEnvironmentVariable("SIMULATED_FAILURE_RATE"), out int simulatedFailureRate))
                {
                    if (simulatedFailureRate > 0 && DateTime.UtcNow.Millisecond < (simulatedFailureRate / 100) * 1000)
                    {
                        throw new Exception("Random Exception from SbConsumer");
                    }
                }

                await messageActions.CompleteMessageAsync(message);

                log.LogInformation($"Processed Profile ID: {message.SessionId} in {sw.ElapsedMilliseconds}ms");
            }
            //TODO: https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-exceptions
            catch (ServiceBusException ex)
            {
                await ExceptionHelper("Service Bus Exception", messageActions, message, ex, log);
            }
            catch (CosmosException ex)
            {
                await ExceptionHelper("Cosmos Exception", messageActions, message, ex, log);
            }
            catch (Exception ex)
            {
                await ExceptionHelper("Unknown Exception", messageActions, message, ex, log);
                throw;
            }
        }

        private static async Task ExceptionHelper(string exceptionType, ServiceBusMessageActions messageActions, ServiceBusReceivedMessage message, Exception ex, ILogger log)
        {
            await messageActions.AbandonMessageAsync(message);
            log.LogError(ex, $"{exceptionType} when consuming messages from topic {Environment.GetEnvironmentVariable("QueueName")}");
        }

        [FunctionName("UpsertAddresses")]
        public async Task<IActionResult> UpsertAddresses([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req, ILogger log)
        {
            var sw = Stopwatch.StartNew();
            if (!int.TryParse(req.Query["addressCount"], out int addressCount))
            {
                addressCount = 1;
            }
            if (addressCount < 1)
            {
                addressCount = 1;
            }

            if (!int.TryParse(Environment.GetEnvironmentVariable("PROFILE_ID_MAX_RANGE"), out int profileIdMaxRange))
            {
                profileIdMaxRange = 50000; //Set a default max range for profile IDs if one isn't configured
            }
            var id = _random.Next(0, profileIdMaxRange);

            var addresses = new List<Address>();
            for (int i = 0; i < addressCount; i++)
            {
                var addressGenerator = new Faker<Address>()
                .StrictMode(false)
                .Rules((f, a) =>
                {
                    a.Street1 = f.Address.StreetAddress(false);
                    a.Street2 = f.Address.SecondaryAddress();
                    a.City = f.Address.City();
                    a.State = f.Address.StateAbbr();
                    a.Zip = f.Address.ZipCode();
                    a.ZipExtension = f.Random.Number(1000, 9999).ToString();
                    a.CreatedDateUtc = DateTime.UtcNow;
                    a.UpdatedDateUtc = DateTime.UtcNow;
                });
                var address = addressGenerator.Generate();
                address.Id = id.ToString();
            }

            await _cosmosDbService.UpsertTargetAddresses(addresses);

            return new OkObjectResult($"Upserted {addressCount} addresses in {sw.ElapsedMilliseconds}ms");
        }
    }
}
