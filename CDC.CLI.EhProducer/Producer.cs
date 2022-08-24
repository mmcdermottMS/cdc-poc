using Azure.Identity;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Bogus;
using CDC.Domain;
using Newtonsoft.Json;
using System.Diagnostics;

namespace CDC.CLI.EhProducer
{
    internal class Producer
    {
        private readonly EventHubProducerClient eventHubProducerClient;
        private readonly Random random = new();

        public Producer(string eventHubNameSpace, string ehName)
        {
            eventHubProducerClient = new EventHubProducerClient(eventHubNameSpace, ehName, new DefaultAzureCredential());
        }

        public async Task PublishMessages(int messageCount, int partitionCount, int numCycles, int delayMs)
        {
            for (int cycle = 0; cycle <= numCycles; cycle++)
            {
                var sw = Stopwatch.StartNew();
                Thread.Sleep(delayMs);
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
                        a.ZipCode = $"{f.Address.ZipCode()}-{f.Random.Number(1000, 9999)}";
                        a.CreatedDateUtc = DateTime.UtcNow;
                        a.UpdatedDateUtc = DateTime.UtcNow;
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

                        var wrapper = new ConnectWrapper
                        {
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
                                CreatedDateUtc = new MongoAddress.MongoDate() { Value = (long)address.CreatedDateUtc.Subtract(new DateTime(1970, 1, 1)).TotalMilliseconds }
                            })
                        };

                        addresses.Add(wrapper);
                    }
                }

                await SendBatch(addresses);

                Console.WriteLine($"Cycle {cycle}: {sw.ElapsedMilliseconds}ms to generate and publish {addresses.Count} address changes messages to {partitionCount} EH partitions");
            }
        }

        private async Task SendBatch(List<ConnectWrapper> addresses)
        {
            var sw = Stopwatch.StartNew();
            var eventDataBatch = await eventHubProducerClient.CreateBatchAsync();
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
            Console.WriteLine($"Generated batch of {addresses.Count} addresses in {sw.ElapsedMilliseconds}ms");
        }
    }
}
