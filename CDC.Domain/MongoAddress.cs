using Newtonsoft.Json;

namespace CDC.Domain
{
    public class MongoAddress
    {
        [JsonProperty("_id")]
        public MongoId? Id { get; set; }

        public MongoProfileId? ProfileId { get; set; }

        public string? Street1 { get; set; }

        public string? Street2 { get; set; }

        public string? Street3 { get; set; }

        public string? City { get; set; }

        public string? State { get; set; }

        public string? ZipCode { get; set; }

        public MongoDate? CreatedDateUtc { get; set; }

        public MongoDate? UpdatedDateUtc { get; set; }

        public class MongoId
        {
            [JsonProperty("$oid")]
            public string? Oid { get; set; }
        }

        public class MongoProfileId
        {
            [JsonProperty("$numberLong")]
            public string? Value { get; set; }
        }

        public class MongoDate
        {
            [JsonProperty("$date")]
            public long Value { get; set; }
        }
    }
}