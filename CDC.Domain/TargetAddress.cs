﻿using Newtonsoft.Json;

namespace CDC.Domain
{
    public class TargetAddress
    {
        [JsonProperty("id")]
        public string? Id { get; set; }

        [JsonProperty("profileId")]
        public string? ProfileId { get; set; }

        public string? Street1 { get; set; }

        public string? Street2 { get; set; }

        public string? City { get; set; }

        public string? State { get; set; }

        public string? Zip { get; set; }

        public string? ZipExtension { get; set; }

        public DateTime CreatedDateUtc { get; set; }

        public DateTime UpdatedDateUtc { get; set; }

        public double LatencyMs { get; set; }
    }
}
