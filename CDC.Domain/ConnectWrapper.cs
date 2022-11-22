using System.Text.Json.Serialization;

namespace CDC.Domain
{
    public class ConnectWrapper
    {
        [JsonPropertyName("CustomerId")]
        public long CustomerId { get; set; }

        [JsonPropertyName("schema")]
        public Schema? Schema { get; set; }

        [JsonPropertyName("payload")]
        public string? Payload { get; set; }
    }

    public class Schema
    {
        [JsonPropertyName("type")]
        public string? Type { get; set; }

        [JsonPropertyName("optional")]
        public bool? Optional { get; set; }
    }
}
