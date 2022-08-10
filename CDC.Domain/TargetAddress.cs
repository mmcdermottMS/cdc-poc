using Newtonsoft.Json;

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

        public DateTime DateCreated { get; set; }

        public DateTime DateUpdated { get; set; }
    }
}
