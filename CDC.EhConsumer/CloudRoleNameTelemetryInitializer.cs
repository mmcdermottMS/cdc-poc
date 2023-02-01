using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.Extensibility;

namespace CDC.EhConsumer
{
    public class CloudRoleNameTelemetryInitializer : ITelemetryInitializer
    {
        public void Initialize(ITelemetry telemetry)
        {
            //Setting this to a custom value is helpful when viewing within Application Insights Live Metrics or Application Map,
            //however it will break the Invocations sub-tab on the Monitor tab for a given function, preventing any data from showing
            //This is becuase under the covers it is just running a kusto query against the requests table in App Insights Logs but 
            //defaults to the function name as the cloud role name instead of your custom value.
            //telemetry.Context.Cloud.RoleName = "EventHubConsumer";
        }
    }
}
