using Microsoft.Azure.Cosmos;

namespace CDC.EhProducer
{
    internal static class CosmosInitializer
    {
        internal static async Task Initalize()
        {
            using CosmosClient cosmosClient = new CosmosClient(
                accountEndpoint: "https://cdc-poc-wus-cdb.documents.azure.com",
                authKeyOrResourceToken: "niP9Ahk5dL6VVpm1DADn8C1AHSsZCfWgTJqZ67ULLz28E3WBoAvw9O0IufQ45fNkJeKAiTAWwap2kjeZ5RTcSg=="
            );

            var databaseResponse = await cosmosClient.CreateDatabaseIfNotExistsAsync(id: "Customers");

            var container = await databaseResponse.Database.CreateContainerIfNotExistsAsync(id: "addresses", partitionKeyPath: "/profileId");
        }
    }
}
