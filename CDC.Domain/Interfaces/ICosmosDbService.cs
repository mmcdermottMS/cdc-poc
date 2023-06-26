namespace CDC.Domain.Interfaces
{
    public interface ICosmosDbService
    {
        Task<Address> GetTargetAddressByProfileIdAsync(string profileId);

        Task UpsertTargetAddress(Address targetAddress);
    }
}
