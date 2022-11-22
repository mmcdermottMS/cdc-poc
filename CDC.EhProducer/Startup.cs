using Azure.Identity;
using Azure.Messaging.EventHubs.Producer;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;
using System;

[assembly: FunctionsStartup(typeof(CDC.EhProducer.Startup))]
namespace CDC.EhProducer
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            builder.Services.AddSingleton<ITelemetryInitializer, CloudRoleNameTelemetryInitializer>();
            builder.Services.AddSingleton<IProducer, Producer>();
            builder.Services.AddSingleton(new EventHubProducerClient(Environment.GetEnvironmentVariable("EhNameSpace"), Environment.GetEnvironmentVariable("EhName"), new DefaultAzureCredential()));
        }
    }
}
