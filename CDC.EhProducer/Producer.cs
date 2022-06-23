﻿using Azure.Identity;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Bogus;
using Newtonsoft.Json;
using System.Diagnostics;

namespace CDC.EhProducer
{
    internal class Producer
    {
        private readonly EventHubProducerClient eventHubProducerClient;
        private const string eventHubNameSpace = "cdc-poc-eus-ehns-01.servicebus.windows.net";
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
            var addresses = new List<Address>();

            var addressGenerator = new Faker<Address>()
                .StrictMode(false)
                .Rules((f, a) =>
                {
                    a.ProfileId = Guid.NewGuid();
                    a.Street1 = f.Address.StreetAddress(false);
                    a.Street2 = f.Address.SecondaryAddress();
                    a.Street3 = f.Address.SecondaryAddress();
                    a.City = f.Address.City();
                    a.State = f.Address.StateAbbr();
                    a.ZipCode = f.Address.ZipCode();
                });

            var sw = Stopwatch.StartNew();
            for (int i = 0; i < messageCount; i++)
            {
                addresses.Add(addressGenerator.Generate());
            }
            Console.WriteLine($"{sw.ElapsedMilliseconds}ms to generate {messageCount} addressses");

            var addressesByPartition = addresses.GroupBy(_ => Math.Abs(_.ProfileId.GetHashCode() % partitionCount)).ToDictionary(_ => _.Key, __ => __.ToList());

            sw = Stopwatch.StartNew();
            foreach (var addressPartition in addressesByPartition)
            {
                var eventDataBatch = await eventHubProducerClient.CreateBatchAsync(new CreateBatchOptions { PartitionId = addressPartition.Key.ToString() });
                foreach (var address in addressPartition.Value)
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
                Console.WriteLine($"Generated batch of {addressPartition.Value.Count} addresses for partition ID {addressPartition.Key}");
            }

            var partitionIds = await eventHubProducerClient.GetPartitionIdsAsync();
            if (partitionIds.Length != partitionCount)
                Console.WriteLine($"WARNING: Specified partition count ({partitionCount}) does not match partition count on target Event Hub ({partitionIds.Length})");

            Console.WriteLine($"{sw.ElapsedMilliseconds}ms to publish {addresses.Count} address changes messages to {partitionCount} EH partitions");
        }
    }
}
