using CDC.Domain.Interfaces;
using CDC.SbConsumer;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;

[assembly: FunctionsStartup(typeof(CDC.Startup))]
namespace CDC
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            builder.Services.AddApplicationInsightsTelemetryWorkerService();
            builder.Services.AddSingleton<ICosmosDbService>(new CosmosDbService(new CosmosClient(
                accountEndpoint: "https://cdc-poc-wus-cdb.documents.azure.com",
                authKeyOrResourceToken: ""
            )));
        }
    }
}
