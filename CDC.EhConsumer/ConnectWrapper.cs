using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace CDC.EhConsumer
{
    internal class ConnectWrapper
    {
        [JsonPropertyName("schema")]
        public Schema Schema { get; set; }

        [JsonPropertyName("payload")]
        public string Payload { get; set; }
    }

    internal class Schema
    {
        [JsonPropertyName("type")]
        public string Type { get; set; }

        [JsonPropertyName("optional")]
        public bool Optional { get; set; }
    }
}
