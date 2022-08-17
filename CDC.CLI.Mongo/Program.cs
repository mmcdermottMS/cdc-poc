using Bogus;
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
            if (int.TryParse(args[0], out int numMsgs))
            {
                IConfigurationBuilder builder = new ConfigurationBuilder().AddJsonFile("local.settings.json", false, true);
                IConfigurationRoot configurationRoot = builder.Build();

                MongoClient mongoClient = new(configurationRoot["mongoDbConnString"]);

                var database = mongoClient.GetDatabase("Customers");
                var collection = database.GetCollection<SourceAddress>("addresses");

                var addresses = GenerateAddresses(numMsgs);
                await collection.InsertManyAsync(addresses);

                Console.WriteLine($"Generated {addresses.Count} addresses");
            }
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
                    a.CreatedDate = DateTime.UtcNow;
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