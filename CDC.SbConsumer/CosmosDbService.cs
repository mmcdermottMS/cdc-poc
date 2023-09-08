using Azure.Core;
using Azure.Identity;
using CDC.Domain;
using CDC.Domain.Interfaces;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace CDC.SbConsumer
{
    internal class CosmosDbService : ICosmosDbService
    {
        private readonly CosmosClient _cosmosClient;
        private readonly Database _database;
        private readonly Container _container;
        private readonly ILogger<CosmosDbService> _logger;

        public CosmosDbService(ILogger<CosmosDbService> logger)
        {
            _cosmosClient = new CosmosClient(Environment.GetEnvironmentVariable("CosmosHost"), new DefaultAzureCredential(new DefaultAzureCredentialOptions { ManagedIdentityResourceId = new ResourceIdentifier(Environment.GetEnvironmentVariable("COSMOS_WRITER_MI_RESOURCE_ID")) }), new CosmosClientOptions() { AllowBulkExecution = true });
            //_cosmosClient = new CosmosClient(Environment.GetEnvironmentVariable("CosmosHost"), new CosmosClientOptions() { AllowBulkExecution = true });
            _database = _cosmosClient.GetDatabase("Customers");
            _container = _database.GetContainer("addresses");
            _logger = logger;
        }

        public async Task<Address> GetTargetAddressByIdAsync(string id)
        {
            Address result = null;
            var query = new QueryDefinition(query: "SELECT * FROM addresses a WHERE a.id = @key").WithParameter("@key", id);

            try
            {
                using FeedIterator<Address> feed = _container.GetItemQueryIterator<Address>(queryDefinition: query);

                while (feed.HasMoreResults)
                {
                    FeedResponse<Address> response = await feed.ReadNextAsync();
                    if (response != null && response.Count > 0)
                    {
                        result = response.First();
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error trying to lookup target address");
            }

            return result;
        }

        public async Task UpsertTargetAddress(Address targetAddress)
        {
            var partitionKey = new PartitionKey(targetAddress.Id);
            await _container.UpsertItemAsync<Address>(item: targetAddress, partitionKey: partitionKey);
        }

        public async Task UpsertTargetAddresses(ICollection<Address> targetAddresses)
        {
            var tasks = new List<Task>(targetAddresses.Count);
            foreach(var address in targetAddresses)
            {
                tasks.Add(_container.UpsertItemAsync(address, new PartitionKey(address.Id)).ContinueWith(itemResponse =>
                {
                    if (!itemResponse.IsCompletedSuccessfully)
                    {
                        AggregateException innerExceptions = itemResponse.Exception.Flatten();
                        if (innerExceptions.InnerExceptions.FirstOrDefault(innerEx => innerEx is CosmosException) is CosmosException cosmosException)
                        {
                            Console.WriteLine($"Received {cosmosException.StatusCode} ({cosmosException.Message}).");
                        }
                        else
                        {
                            Console.WriteLine($"Exception {innerExceptions.InnerExceptions.FirstOrDefault()}.");
                        }
                    }
                }));
            }

            await Task.WhenAll(tasks);
        }

        public async Task<Address> GetByIdAsync(string id)
        {
            try
            {
                return await _container.ReadItemAsync<Address>(id, new PartitionKey(id));
            }
            catch (CosmosException ex)
            {
                if (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return null;
                }
                else
                {
                    throw ex;
                }
            }
        }
    }
}
