using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Bogus;
using CDC.Domain;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;

namespace CDC.EhProducer
{
    public class Producer : IProducer
    {
        private readonly EventHubProducerClient _eventHubProducerClient;
        private readonly Random _random;
        private readonly HttpClient _httpClient;
        private readonly ILogger<Producer> _logger;
        private readonly int _targetMessageSize = 300000;

        public Producer(EventHubProducerClient eventHubProducerClient, ILogger<Producer> logger)
        {
            _eventHubProducerClient = eventHubProducerClient;
            _logger = logger;
            _random = new Random();
            _httpClient = new HttpClient();
        }

        public async Task PublishMessages(int messageCount, int numCycles, int delayMs, int partitionCount)
        {
            var sendOversizedMessages = int.TryParse(Environment.GetEnvironmentVariable("OVERSIZE_MESSAGE_RATE"), out int oversizeMessageRate);

            var paragraphs = string.Empty;
            if (sendOversizedMessages && oversizeMessageRate > 0)
            {
                var faker = new Faker();
                //paragraphs = faker.Lorem.Paragraphs(5000);
                paragraphs = faker.Lorem.Paragraphs(1350);

                if (paragraphs.Length > _targetMessageSize)
                {
                    paragraphs = paragraphs[.._targetMessageSize];
                }
            }

            if (!int.TryParse(Environment.GetEnvironmentVariable("PROFILE_ID_MAX_RANGE"), out int profileIdMaxRange))
            {
                profileIdMaxRange = 50000; //Set a default max range for profile IDs if one isn't configured
            }

            if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("ExternalApiUri")))
            {
                var apiCallResult = await _httpClient.GetAsync(Environment.GetEnvironmentVariable("ExternalApiUri"));
                _logger.LogInformation($"Successfully made API call to {Environment.GetEnvironmentVariable("ExternalApiUri")}: {apiCallResult.Content}");
            }

            for (int cycle = 0; cycle < numCycles; cycle++)
            {
                var sw = Stopwatch.StartNew();
                Randomizer.Seed = _random;

                var addresses = new List<Address>();

                //See: https://github.com/bchavez/Bogus
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

                for (int i = 0; i < messageCount; i++)
                {
                    var address = addressGenerator.Generate();

                    if (sendOversizedMessages)
                    {
                        if (i % oversizeMessageRate == 0)
                        {
                            address.Street2 = paragraphs;
                        }
                    }

                    address.Id = _random.Next(profileIdMaxRange).ToString();
                    //address.Id = Guid.NewGuid().ToString();

                    addresses.Add(address);
                }

                await SendBatch(addresses);

                Thread.Sleep(delayMs);
                _logger.LogInformation($"Cycle {cycle}: {sw.ElapsedMilliseconds}ms to generate and publish {messageCount} address change messages.");
            }
        }

        private async Task SendBatch(List<Address> addresses)
        {
            var sw = Stopwatch.StartNew();
            var eventDataBatch = await _eventHubProducerClient.CreateBatchAsync();

            foreach (var address in addresses)
            {
                var eventData = new EventData(JsonConvert.SerializeObject(address));
                if (!eventDataBatch.TryAdd(eventData))
                {
                    await _eventHubProducerClient.SendAsync(eventDataBatch);

                    eventDataBatch = await _eventHubProducerClient.CreateBatchAsync();

                    if (!eventDataBatch.TryAdd(eventData))
                    {
                        throw new Exception("Generated address is too big for Event Hub batch");
                    }
                }
            }

            await _eventHubProducerClient.SendAsync(eventDataBatch);

            _logger.LogInformation($"Published {addresses.Count} addresses in {sw.ElapsedMilliseconds}ms");
        }
    }
}
