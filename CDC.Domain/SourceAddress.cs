namespace CDC.Domain
{
    public class SourceAddress
    {
        public Guid ProfileId { get; set; }

        public string? Street1 { get; set; }

        public string? Street2 { get; set; }

        public string? Street3 { get; set; }

        public string? City { get; set; }

        public string? State { get; set; }

        public string? ZipCode { get; set; }
    }
}