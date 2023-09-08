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

        public async Task PublishMessages(int messageCount, int numCycles, int delayMs)
        {
            for (int cycle = 0; cycle < numCycles; cycle++)
            {
                var sw = Stopwatch.StartNew();
                Randomizer.Seed = random;

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
                    address.Id = Guid.NewGuid().ToString();

                    addresses.Add(address);
                }

                await SendBatch(addresses);

                Thread.Sleep(delayMs);
                Console.WriteLine($"Cycle {cycle}: {sw.ElapsedMilliseconds}ms to generate and publish {messageCount} address change messages.");
            }
        }

        private async Task SendBatch(List<Address> addresses)
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
