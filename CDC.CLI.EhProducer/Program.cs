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

            if(args.Length < 1 || int.TryParse(args[0], out int messageCount))
            {
                messageCount = 1;
            }

            if (args.Length < 2 || !int.TryParse(args[1], out int numCycles))
            { 
                numCycles = 1; 
            }

            if(args.Length < 3 || !int.TryParse(args[2], out int delayMs))
            {
                delayMs = 0;
            }

            await producer.PublishMessages(messageCount, numCycles, delayMs);
        }
    }
}