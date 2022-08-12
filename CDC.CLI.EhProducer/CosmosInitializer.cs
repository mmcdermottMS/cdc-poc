using Microsoft.Azure.Cosmos;

namespace CDC.CLI.EhProducer
{
    internal static class CosmosInitializer
    {
        internal static async Task Initalize()
        {
            using CosmosClient cosmosClient = new("https://cdc-poc-wus-acdb.documents.azure.com", "G5tAvFo9wa4zOFaXkY8A6gxI35Tn4zJMC9RNiflCAFgxnHZtW3qVmJlJZOLnk9dZXaVu0TlRAQ7QQBPSoNK9kg==");
            var databaseResponse = await cosmosClient.CreateDatabaseIfNotExistsAsync("Customers");
            var container = await databaseResponse.Database.CreateContainerIfNotExistsAsync("addresses", "/profileId");
        }
    }
}
