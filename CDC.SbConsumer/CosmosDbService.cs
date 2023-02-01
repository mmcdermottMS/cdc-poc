﻿using Azure.Identity;
using CDC.Domain;
using CDC.Domain.Interfaces;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Logging;
using System;
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
            _cosmosClient = new CosmosClient(Environment.GetEnvironmentVariable("CosmosHost"), new DefaultAzureCredential());
            _database = _cosmosClient.GetDatabase("Customers");
            _container = _database.GetContainer("addresses");
            _logger = logger;
        }

        public async Task<TargetAddress> GetTargetAddressByProfileIdAsync(string profileId)
        {
            TargetAddress result = null;
            var query = new QueryDefinition(query: "SELECT * FROM addresses a WHERE a.profileId = @key").WithParameter("@key", profileId);

            try
            {
                using FeedIterator<TargetAddress> feed = _container.GetItemQueryIterator<TargetAddress>(queryDefinition: query);

                while (feed.HasMoreResults)
                {
                    FeedResponse<TargetAddress> response = await feed.ReadNextAsync();
                    if (response != null && response.Count > 0)
                    {
                        result = response.First();
                        _logger.LogInformation($"RU Charge for Address Lookup by Profile ID: {response.RequestCharge}");
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error trying to lookup target address");
            }

            return result;
        }

        public async Task UpsertTargetAddress(TargetAddress targetAddress)
        {
            var partitionKey = new PartitionKey(targetAddress.ProfileId);
            await _container.UpsertItemAsync<TargetAddress>(item: targetAddress, partitionKey: partitionKey);
        }
    }
}
