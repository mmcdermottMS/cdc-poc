using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Microsoft.ApplicationInsights;

namespace CDC.EhConsumer
{
    public class EventStreamBacklogTracing
    {
        private readonly TelemetryClient _telemetryClient;

        public EventStreamBacklogTracing(TelemetryClient telemetryClient)
        {
            _telemetryClient = telemetryClient;
        }

        public void LogSequenceDifference(EventData message, PartitionContext context)
        {
            var sequenceDifference = context.ReadLastEnqueuedEventProperties().SequenceNumber - message.SequenceNumber;

            _telemetryClient.GetMetric("PartitionSequenceDifference", "PartitionId", "ConsumerGroupName", "EventHubName")
                .TrackValue(sequenceDifference, context.PartitionId, context.ConsumerGroup, context.EventHubName);
        }
    }
}