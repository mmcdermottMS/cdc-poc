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

            var containerProperties = new ContainerProperties()
            {
                Id = "addresses",
                PartitionKeyPath = "/profileId"
            };

            var throughputProperties = ThroughputProperties.CreateAutoscaleThroughput(int.Parse(Environment.GetEnvironmentVariable("CosmosInitialAutoscaleThroughput")));

            var container = await databaseResponse.Database.CreateContainerIfNotExistsAsync(containerProperties, throughputProperties);
        }
    }
}
