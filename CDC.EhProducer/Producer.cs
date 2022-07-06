using Azure.Identity;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Bogus;
using CDC.Domain;
using Newtonsoft.Json;
using System.Diagnostics;

namespace CDC.EhProducer
{
    internal class Producer
    {
        private readonly EventHubProducerClient eventHubProducerClient;
        private const string eventHubNameSpace = "cdc-poc-wus-ehns-01.servicebus.windows.net";
        private const string ehName = "addresses";

        public Producer()
        {
            eventHubProducerClient = new EventHubProducerClient(eventHubNameSpace, ehName, new DefaultAzureCredential());
        }

        public async Task PublishMessages(string[] args)
        {
            if (args.Length < 2
                || string.IsNullOrEmpty(args[0])
                || !int.TryParse(args[0], out int messageCount)
                || string.IsNullOrEmpty(args[1])
                || !int.TryParse(args[1], out int partitionCount)
                )
            {
                Console.WriteLine("Usage: produce {numOfMessages} {partitionCount}");
                return;
            }

            Randomizer.Seed = new Random(8675309);
            var addresses = new List<SourceAddress>();

            var addressGenerator = new Faker<SourceAddress>()
                .StrictMode(false)
                .Rules((f, a) =>
                {
                    a.Street1 = f.Address.StreetAddress(false);
                    a.Street2 = f.Address.SecondaryAddress();
                    a.City = f.Address.City();
                    a.State = f.Address.StateAbbr();
                    a.ZipCode = $"{f.Address.ZipCode()}-{f.Random.Number(1000, 9999)}";
                });

            var sw = Stopwatch.StartNew();

            //Set it up so that there are 5 events per profile Id to simulate multiple changes right in a 
            //row.  Track the change ID in the Street 3 field.  When all is said and done, we'll know we processed
            //everything in order by verifying that the Street3 field in the target DB is always 5

            var numProfiles = messageCount / 5;
            for (int i = 0; i < numProfiles; i++)
            {
                var profileId = Guid.NewGuid();
                for(int j = 0; j < 5; j++)
                {
                    var address = addressGenerator.Generate();
                    address.ProfileId = profileId;
                    address.Street3 = j.ToString();
                    addresses.Add(address);
                }                
            }


            Console.WriteLine($"{sw.ElapsedMilliseconds}ms to generate {messageCount} addressses");

            var addressesByPartition = addresses.GroupBy(_ => Math.Abs(_.ProfileId.GetHashCode() % partitionCount)).ToDictionary(_ => _.Key, __ => __.ToList());

            var partitionIds = await eventHubProducerClient.GetPartitionIdsAsync();
            if (partitionIds.Length != partitionCount)
                Console.WriteLine($"WARNING: Specified partition count ({partitionCount}) does not match partition count on target Event Hub ({partitionIds.Length})");

            var batches = new List<Task>();
            foreach (var addressPartition in addressesByPartition)
            {
                batches.Add(SendBatch(addressPartition.Value, addressPartition.Key));
            }

            Console.WriteLine("Batch Tasks Created, awaiting all tasks...");
            sw = Stopwatch.StartNew();
            await Task.WhenAll(batches);
            Console.WriteLine($"{sw.ElapsedMilliseconds}ms to publish {addresses.Count} address changes messages to {partitionCount} EH partitions");
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
            Console.WriteLine($"Generated batch of {addresses.Count} addresses for partition ID {partitionId} in {sw.ElapsedMilliseconds}ms");
        }
    }
}
