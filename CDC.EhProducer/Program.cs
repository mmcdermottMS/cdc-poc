using CDC.EhProducer;

namespace CDC
{
    internal class Program
    {
        static async Task Main(string[] args)
        {
            await CosmosInitializer.Initalize();
            var producer = new Producer();
            await producer.PublishMessages(args);
        }
    }
}