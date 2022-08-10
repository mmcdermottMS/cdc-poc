﻿using Newtonsoft.Json;

namespace CDC.EhConsumer
{
    public class MongoAddress
    {
        [JsonProperty("_id")]
        public IdDetails? Id { get; set; }

        public ProfileIdDetails? ProfileId { get; set; }

        public string? Street1 { get; set; }

        public string? Street2 { get; set; }

        public string? Street3 { get; set; }

        public string? City { get; set; }

        public string? State { get; set; }

        public string? ZipCode { get; set; }

        public CreatedDateDetails? CreatedDate { get; set; }

        public class IdDetails
        {
            [JsonProperty("$oid")]
            public string? Oid { get; set; }
        }

        public class ProfileIdDetails
        {
            [JsonProperty("$numberLong")]
            public string? NumberLong { get; set; }
        }

        public class CreatedDateDetails
        {
            [JsonProperty("$date")]
            public long CreatedDate { get; set; }
        }
    }
}