using Microsoft.Azure.Cosmos;
using System;
using System.Threading.Tasks;

namespace CDC.EhProducer
{
    internal static class CosmosInitializer
    {
        internal static async Task Initalize()
        {
            //TODO: An AuthToken must be used for control plane operations such as create database or create container, you cannot use MI for that.
            //Update code to use Managed Identity to retieve the auth token into memory and build the client that way.
            using CosmosClient cosmosClient = new(Environment.GetEnvironmentVariable("CosmosHost"), Environment.GetEnvironmentVariable("CosmosAuthToken"));

            var databaseResponse = await cosmosClient.CreateDatabaseIfNotExistsAsync(id: "Customers");

            var addressContainerProperties = new ContainerProperties()
            {
                Id = "addresses",
                PartitionKeyPath = "/id"
            };

            var summaryContainerProperties = new ContainerProperties()
            {
                Id = "summaries",
                PartitionKeyPath = "/id"
            };

            var movementContainerProperties = new ContainerProperties()
            {
                Id = "movements",
                PartitionKeyPath = "/id"
            };

            var throughputProperties = ThroughputProperties.CreateAutoscaleThroughput(int.Parse(Environment.GetEnvironmentVariable("CosmosInitialAutoscaleThroughput")));

            var addressContainer = await databaseResponse.Database.CreateContainerIfNotExistsAsync(addressContainerProperties, throughputProperties);
            var summaryContainer = await databaseResponse.Database.CreateContainerIfNotExistsAsync(summaryContainerProperties, throughputProperties);
            var movementContainer = await databaseResponse.Database.CreateContainerIfNotExistsAsync(movementContainerProperties, throughputProperties);
        }
    }
}
