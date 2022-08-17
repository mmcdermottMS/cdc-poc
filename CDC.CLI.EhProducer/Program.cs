using CDC.CLI.EhProducer;
using Microsoft.Extensions.Configuration;

namespace CDC
{
    internal class Program
    {
        static async Task Main(string[] args)
        {
            IConfigurationBuilder builder = new ConfigurationBuilder().AddJsonFile("local.settings.json", false, true);
            IConfigurationRoot configurationRoot = builder.Build();

            await CosmosInitializer.Initalize(configurationRoot["CosmosAccount"], configurationRoot["CosmosKey"]);
            var producer = new Producer(configurationRoot["EventHubNameSpace"], configurationRoot["EhName"]);
            await producer.PublishMessages(int.Parse(args[0]), int.Parse(args[1]), 1, 0);
        }
    }
}