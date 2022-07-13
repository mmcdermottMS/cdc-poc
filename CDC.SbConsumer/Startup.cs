using Azure.Identity;
using CDC.Domain.Interfaces;
using CDC.SbConsumer;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;
using System;

[assembly: FunctionsStartup(typeof(CDC.Startup))]
namespace CDC
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            builder.Services.AddApplicationInsightsTelemetryWorkerService();
            builder.Services.AddSingleton<ICosmosDbService>(new CosmosDbService(new CosmosClient(Environment.GetEnvironmentVariable("CosmosHost"), new DefaultAzureCredential())));
        }
    }
}
