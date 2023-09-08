namespace CDC.Domain.Interfaces
{
    public interface ICosmosDbService
    {
        Task<Address> GetTargetAddressByIdAsync(string profileId);

        Task UpsertTargetAddress(Address targetAddress);

        Task UpsertTargetAddresses(ICollection<Address> targetAddresses);

        Task<Address> GetByIdAsync(string id);
    }
}
