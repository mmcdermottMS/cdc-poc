using System.Text.Json.Serialization;

namespace CDC.Domain
{
    public class TargetAddress
    {
        [JsonPropertyName("id")]
        public string? id { get; set; }

        [JsonPropertyName("profileId")]
        public string? profileId { get; set; }

        public string? Street1 { get; set; }

        public string? Street2 { get; set; }

        public string? City { get; set; }

        public string? State { get; set; }

        public string? Zip { get; set; }

        public string? ZipExtension { get; set; }

        public DateTime DateCreated { get; set; }

        public DateTime DateUpdated { get; set; }
    }
}
