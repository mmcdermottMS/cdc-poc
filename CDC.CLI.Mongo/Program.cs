using Bogus;
using Bogus.DataSets;
using CDC.Domain;
using Microsoft.Extensions.Configuration;
using MongoDB.Driver;
using System.Diagnostics;

namespace CDC.CLI.Mongo
{
    internal class Program
    {
        static async Task Main(string[] args)
        {
            int numCycles;
            if (!int.TryParse(args[1], out numCycles))
            {
                numCycles = 1;
            }

            if (int.TryParse(args[0], out int numMsgs))
            {
                IConfigurationBuilder builder = new ConfigurationBuilder().AddJsonFile("local.settings.json", false, true);
                IConfigurationRoot configurationRoot = builder.Build();

                MongoClient mongoClient = new(configurationRoot["mongoDbConnString"]);
                var database = mongoClient.GetDatabase("Customers");
                var collection = database.GetCollection<SourceAddress>("addresses");

                if (args[2].ToLowerInvariant() == "insert" )
                {
                    await InsertRecords(numMsgs, collection);
                } 
                else if (args[2].ToLowerInvariant() == "update")
                {
                    for (int i = 0; i < numCycles; i++)
                    {
                        await UpdateRecords(numMsgs, collection);
                        Thread.Sleep(1000);
                    }
                }
                else 
                {
                    Console.WriteLine("No action taken");
                }

                Console.WriteLine("Done");                
            }
        }

        static async Task InsertRecords(int count, IMongoCollection<SourceAddress> collection)
        {
            var addresses = GenerateAddresses(count);
            await collection.InsertManyAsync(addresses);
            Console.WriteLine($"Inserted {addresses.Count} addresses");
        }

        static async Task UpdateRecords(int count, IMongoCollection<SourceAddress> collection)
        {
            var newStreet3 = Guid.NewGuid().ToString();
            var filter = Builders<SourceAddress>.Filter.Lt("ProfileId", count.ToString());
            var update = Builders<SourceAddress>.Update.Set("Street3", newStreet3);

            await collection.UpdateManyAsync(filter, update);

            Console.WriteLine($"Updated count addresses");
        }

        static List<SourceAddress> GenerateAddresses(int messageCount)
        {
            Random random = new();
            var addresses = new List<SourceAddress>();

            var sw = Stopwatch.StartNew();
            Randomizer.Seed = random;

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

            for (int profileId = 1; profileId <= messageCount; profileId++)
            {
                var address = addressGenerator.Generate();
                address.ProfileId = profileId;
                address.Street3 = "1";
                addresses.Add(address);
            }

            return addresses;
        }
    }
}