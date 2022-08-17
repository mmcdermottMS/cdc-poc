using Microsoft.Azure.Cosmos;

namespace CDC.CLI.EhProducer
{
    internal static class CosmosInitializer
    {
        internal static async Task Initalize(string cosmosAccount, string cosmosKey)
        {
            using CosmosClient cosmosClient = new(cosmosAccount, cosmosKey);
            var databaseResponse = await cosmosClient.CreateDatabaseIfNotExistsAsync("Customers");
            var container = await databaseResponse.Database.CreateContainerIfNotExistsAsync("addresses", "/profileId");
        }
    }
}
