using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

[assembly: FunctionsStartup(typeof(CDC.EhConsumer.Startup))]
namespace CDC.EhConsumer
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            builder.Services.AddSingleton<ITelemetryInitializer, CloudRoleNameTelemetryInitializer>();
            builder.Services.AddSingleton<TelemetryClient, TelemetryClient>();

            var wjBuilder = builder.Services.AddWebJobs(_ => { });

            // This method allows you to mutate the options used to 
            // create the Event Hubs clients and set the transport.
            wjBuilder.AddEventHubs(options =>
            {
                options.TrackLastEnqueuedEventProperties = true;
                options.BatchCheckpointFrequency = 1;
                options.MaxEventBatchSize = 1;
            });

            wjBuilder.AddBuiltInBindings();
            wjBuilder.AddExecutionContextBinding();
        }
    }
}
