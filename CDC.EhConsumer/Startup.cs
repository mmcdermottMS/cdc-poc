using Azure.Identity;
using Azure.Messaging.ServiceBus;
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
            builder.Services.AddLogging();
            builder.Services.AddApplicationInsightsTelemetryWorkerService();
            builder.Services.AddSingleton(new ServiceBusClient(Environment.GetEnvironmentVariable("ServiceBusHostName"), new DefaultAzureCredential()));
        }
    }
}
