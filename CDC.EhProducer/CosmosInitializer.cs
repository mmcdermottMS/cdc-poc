using Microsoft.Azure.Cosmos;

namespace CDC.EhProducer
{
    internal static class CosmosInitializer
    {
        internal static async Task Initalize()
        {
            using CosmosClient cosmosClient = new CosmosClient(
                accountEndpoint: "https://cdc-poc-wus-cdb.documents.azure.com",
                authKeyOrResourceToken: ""
            );

            var databaseResponse = await cosmosClient.CreateDatabaseIfNotExistsAsync(id: "Customers");

            var container = await databaseResponse.Database.CreateContainerIfNotExistsAsync(id: "addresses", partitionKeyPath: "/profileId");
        }
    }
}
