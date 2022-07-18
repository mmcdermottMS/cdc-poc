namespace CDC.Domain.Interfaces
{
    public interface ICosmosDbService
    {
        Task<TargetAddress> GetTargetAddressByProfileIdAsync(string profileId);

        Task UpsertTargetAddress(TargetAddress targetAddress);
    }
}
