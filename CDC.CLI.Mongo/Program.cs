using Bogus;
using CDC.Domain;
using MongoDB.Driver;
using System.Diagnostics;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;

namespace CDC.CLI.Mongo
{
    internal class Program
    {
        static async Task Main(string[] args)
        {
            using IHost host = Host.CreateDefaultBuilder(args).Build();
            IConfigurationBuilder builder = new ConfigurationBuilder().AddJsonFile("local.settings.json", false, true);
            IConfigurationRoot root = builder.Build();

            MongoClient mongoClient = new(root["mongoDbConnString"]);

            var database = mongoClient.GetDatabase("Customers");
            var collection = database.GetCollection<SourceAddress>("addresses");

            var addresses = GenerateAddresses(50, 2);
            await collection.InsertManyAsync(addresses);

            Console.WriteLine($"Generated {addresses.Count} addresses");

            await host.RunAsync();
        }

        static List<SourceAddress> GenerateAddresses(int messageCount, int numCycles)
        {
            Random random = new();
            var addresses = new List<SourceAddress>();
            for (int cycle = 0; cycle <= numCycles; cycle++)
            {
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
                        a.CreatedDate = DateTime.UtcNow;
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

                
            }
            return addresses;
        }
    }
}