using Azure.Identity;
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
using System.Threading;
using System.Threading.Tasks;

namespace CDC.EhProducer
{
    internal class Producer
    {
        private readonly EventHubProducerClient eventHubProducerClient;
        private readonly ILogger log;
        private readonly Random random = new(8675309);

        public Producer(ILogger logger)
        {
            eventHubProducerClient = new EventHubProducerClient(Environment.GetEnvironmentVariable("EhNamespace"), Environment.GetEnvironmentVariable("EhName"), new DefaultAzureCredential());
            log = logger;
        }

        public async Task PublishMessages(int messageCount, int partitionCount, int numCycles, int delayMs)
        {
            for (int cycle = 0; cycle <= numCycles; cycle++)
            {
                var sw = Stopwatch.StartNew();
                Thread.Sleep(delayMs);
                Randomizer.Seed = random;
                var addresses = new List<SourceAddress>();

                //See: https://github.com/bchavez/Bogus
                var addressGenerator = new Faker<SourceAddress>()
                    .StrictMode(false)
                    .Rules((f, a) =>
                    {
                        a.Street1 = f.Address.StreetAddress(false);
                        a.Street2 = f.Address.SecondaryAddress();
                        a.City = f.Address.City();
                        a.State = f.Address.StateAbbr();
                        a.ZipCode = $"{f.Address.ZipCode()}-{f.Random.Number(1000, 9999)}";
                        a.CreatedDateUtc = DateTime.UtcNow;
                    });

                //Set it up so that there are 5 events per profile Id to simulate multiple changes right in a 
                //row.  Track the change ID in the Street 3 field.  When all is said and done, we'll know we processed
                //everything in order by verifying that the Street3 field in the target DB is always 5

                var numProfiles = messageCount / 5;
                for (int profileId = 1; profileId <= numProfiles; profileId++)
                {
                    for (int j = 0; j < 5; j++)
                    {
                        var address = addressGenerator.Generate();
                        address.ProfileId = profileId + (numProfiles * cycle);
                        address.Street3 = j.ToString();
                        addresses.Add(address);
                    }
                }

                var addressesByPartition = addresses.GroupBy(_ => Math.Abs(_.ProfileId.GetHashCode() % partitionCount)).ToDictionary(_ => _.Key, __ => __.ToList());

                var partitionIds = await eventHubProducerClient.GetPartitionIdsAsync();
                if (partitionIds.Length != partitionCount)
                    log.LogWarning($"WARNING: Specified partition count ({partitionCount}) does not match partition count on target Event Hub ({partitionIds.Length})");

                var batches = new List<Task>();
                foreach (var addressPartition in addressesByPartition)
                {
                    batches.Add(SendBatch(addressPartition.Value, addressPartition.Key));
                }
                
                await Task.WhenAll(batches);
                log.LogInformation($"Cycle {cycle}: {sw.ElapsedMilliseconds}ms to generate and publish {addresses.Count} address changes messages to {partitionCount} EH partitions");
            }
        }

        private async Task SendBatch(List<SourceAddress> addresses, int partitionId)
        {
            var sw = Stopwatch.StartNew();
            var eventDataBatch = await eventHubProducerClient.CreateBatchAsync(new CreateBatchOptions { PartitionId = partitionId.ToString() });
            foreach (var address in addresses)
            {
                if (!eventDataBatch.TryAdd(new EventData(JsonConvert.SerializeObject(address))))
                {
                    await eventHubProducerClient.SendAsync(eventDataBatch);

                    eventDataBatch = await eventHubProducerClient.CreateBatchAsync();

                    var eventData = new EventData(JsonConvert.SerializeObject(address));

                    if (!eventDataBatch.TryAdd(eventData))
                    {
                        throw new Exception("Generated address is too big for Event Hub batch");
                    }
                }
            }

            await eventHubProducerClient.SendAsync(eventDataBatch);
            log.LogInformation($"Generated batch of {addresses.Count} addresses for partition ID {partitionId} in {sw.ElapsedMilliseconds}ms");
        }
    }
}
