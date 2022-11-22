using Microsoft.Extensions.Logging;
using System.Threading.Tasks;

namespace CDC.EhProducer
{
    public interface IProducer
    {
        ILogger Log { get; set; }

        Task PublishMessages(int messageCount, int numCycles, int delayMs, int partitionCount);
    }
}
