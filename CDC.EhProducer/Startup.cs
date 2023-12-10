using Azure.Core;
using Azure.Identity;
using Azure.Messaging.EventHubs.Producer;
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
            builder.Services.AddSingleton<IProducer, Producer>();
            builder.Services.AddSingleton(new EventHubProducerClient(Environment.GetEnvironmentVariable("EhNameSpace"), Environment.GetEnvironmentVariable("EhName"), new DefaultAzureCredential(new DefaultAzureCredentialOptions { ManagedIdentityResourceId = new ResourceIdentifier(Environment.GetEnvironmentVariable("EHNS_SENDER_MI_RESOURCE_ID")) })));
        }
    }
}
