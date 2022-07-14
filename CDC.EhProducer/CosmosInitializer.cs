using Microsoft.Azure.Cosmos;
using System;
using System.Threading.Tasks;

namespace CDC.EhProducer
{
    internal static class CosmosInitializer
    {
        internal static async Task Initalize()
        {
            using CosmosClient cosmosClient = new(Environment.GetEnvironmentVariable("CosmosDbAccount"), Environment.GetEnvironmentVariable("CosmosAuthToken"));

            var databaseResponse = await cosmosClient.CreateDatabaseIfNotExistsAsync(id: "Customers");

            var container = await databaseResponse.Database.CreateContainerIfNotExistsAsync(id: "addresses", partitionKeyPath: "/profileId");
        }
    }
}
