namespace CDC.Domain.Interfaces
{
    public interface ICosmosDbService
    {
        Task<TargetAddress> GetTargetAddressByProfileIdAsync(Guid profileId);

        Task UpsertTargetAddress(TargetAddress targetAddress);
    }
}
