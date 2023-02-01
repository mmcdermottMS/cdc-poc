using CDC.Domain.Interfaces;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;

[assembly: FunctionsStartup(typeof(CDC.SbConsumer.Startup))]
namespace CDC.SbConsumer
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            builder.Services.AddSingleton<ICosmosDbService, CosmosDbService>();
            builder.Services.AddSingleton<ITelemetryInitializer, CloudRoleNameTelemetryInitializer>();
        }
    }
}
