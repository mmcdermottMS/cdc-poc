using CDC.CLI.EhProducer;

namespace CDC
{
    internal class Program
    {
        static async Task Main(string[] args)
        {
            await CosmosInitializer.Initalize();
            var producer = new Producer();
            await producer.PublishMessages(int.Parse(args[0]), int.Parse(args[1]), 1, 0);
        }
    }
}