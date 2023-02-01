using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Bogus;
using CDC.Domain;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;

namespace CDC.EhProducer
{
    public class Producer : IProducer
    {
        private readonly EventHubProducerClient _eventHubProducerClient;
        private readonly Random random = new(8675309);
        private readonly HttpClient httpClient = new();
        private readonly ILogger<Producer> _logger;

        public Producer(EventHubProducerClient eventHubProducerClient, ILogger<Producer> logger)
        {
            _eventHubProducerClient = eventHubProducerClient;
            _logger = logger;
        }

        public async Task PublishMessages(int messageCount, int numCycles, int delayMs, int partitionCount)
        {
            var apiCallResult = await httpClient.GetAsync(Environment.GetEnvironmentVariable("ExternalApiUri"));
            _logger.LogInformation($"Successfully made API call to {Environment.GetEnvironmentVariable("ExternalApiUri")}");

            for (int cycle = 0; cycle < numCycles; cycle++)
            {
                var sw = Stopwatch.StartNew();
                Randomizer.Seed = random;

                var addresses = new List<ConnectWrapper>();

                //See: https://github.com/bchavez/Bogus
                var addressGenerator = new Faker<SourceAddress>()
                    .StrictMode(false)
                    .Rules((f, a) =>
                    {
                        a.Street1 = f.Address.StreetAddress(false);
                        a.Street2 = f.Address.SecondaryAddress();
                        a.City = f.Address.City();
                        a.State = f.Address.StateAbbr();
                        a.ZipCode = $"{f.Address.ZipCode()}-{f.Random.Number(10000, 99999)}";
                        a.CreatedDateUtc = DateTime.UtcNow;
                        a.UpdatedDateUtc = DateTime.UtcNow;
                    });

                for (int i = 0; i < messageCount; i++)
                {
                    var address = addressGenerator.Generate();
                    address.ProfileId = random.Next(1, 500000);

                    var wrapper = new ConnectWrapper
                    {
                        CustomerId = address.ProfileId,
                        Schema = new Schema
                        {
                            Optional = false,
                            Type = "string"
                        },
                        Payload = JsonConvert.SerializeObject(new MongoAddress()
                        {
                            Id = new MongoAddress.MongoId() { Oid = Guid.NewGuid().ToString() },
                            ProfileId = new MongoAddress.MongoProfileId() { Value = address.ProfileId.ToString() },
                            Street1 = address.Street1,
                            Street2 = address.Street2,
                            Street3 = address.Street3,
                            City = address.City,
                            State = address.State,
                            ZipCode = address.ZipCode,
                            CreatedDateUtc = new MongoAddress.MongoDate() { Value = (long)address.CreatedDateUtc.Subtract(new DateTime(1970, 1, 1)).TotalMilliseconds },
                            UpdatedDateUtc = new MongoAddress.MongoDate() { Value = (long)address.UpdatedDateUtc.Subtract(new DateTime(1970, 1, 1)).TotalMilliseconds }
                        })
                    };

                    addresses.Add(wrapper);
                }

                await SendBatch(addresses, partitionCount);

                Thread.Sleep(delayMs);
                _logger.LogInformation($"Cycle {cycle}: {sw.ElapsedMilliseconds}ms to generate and publish {messageCount} address change messages.");
            }
        }

        private async Task SendBatch(List<ConnectWrapper> addresses, int partitionCount)
        {
            var sw = Stopwatch.StartNew();

            //Had trouble with the EventHubBufferedProducerClient so manually partitioning the addresses by customer Id
            var addressBatches = addresses.GroupBy(_ => _.CustomerId % partitionCount).ToDictionary(y => y.Key, y => y.ToList());

            foreach (var addresssBatch in addressBatches)
            {
                var createBatchOptions = new CreateBatchOptions() { PartitionKey = addresssBatch.Key.ToString() };
                var eventDataBatch = await _eventHubProducerClient.CreateBatchAsync(createBatchOptions);

                foreach(var address in addresssBatch.Value)
                {
                    var eventData = new EventData(JsonConvert.SerializeObject(address));
                    if (!eventDataBatch.TryAdd(eventData))
                    {
                        await _eventHubProducerClient.SendAsync(eventDataBatch);

                        eventDataBatch = await _eventHubProducerClient.CreateBatchAsync(createBatchOptions);

                        if (!eventDataBatch.TryAdd(eventData))
                        {
                            throw new Exception("Generated address is too big for Event Hub batch");
                        }
                    }
                }
                
                await _eventHubProducerClient.SendAsync(eventDataBatch);
                _logger.LogInformation($"Published {addresssBatch.Value.Count} addresses to Partition Key: {createBatchOptions.PartitionKey}");
            }

            _logger.LogInformation($"Published {addresses.Count} addresses in {sw.ElapsedMilliseconds}ms");
        }
    }
}
