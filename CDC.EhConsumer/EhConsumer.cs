using Azure.Identity;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Consumer;
using Azure.Messaging.ServiceBus;
using CDC.Domain;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading.Tasks;

namespace CDC.EhConsumer
{
    public class EhConsumer
    {
        private readonly ServiceBusClient _serviceBusClient;
        private readonly ServiceBusSender _serviceBusSender;
        private readonly HttpClient _httpClient;

        public EhConsumer()
        {
            _serviceBusClient = new(Environment.GetEnvironmentVariable("ServiceBusHostName"), new DefaultAzureCredential());
            _serviceBusSender = _serviceBusClient.CreateSender(Environment.GetEnvironmentVariable("QueueName"));
            _httpClient = new HttpClient
            {
                BaseAddress = new Uri(Environment.GetEnvironmentVariable("BaseWeatherUri"))
            };
        }

        [FunctionName("EhConsumer")]
        public async Task Run([EventHubTrigger("%EhName%", Connection = "EhNameSpace")] EventData[] events, ILogger log, PartitionContext partitionContext)
        {
            log.LogInformation($"Received {events.Length} events for partition ID {partitionContext.PartitionId}");

            var exceptions = new List<Exception>();

            try
            {
                var sw = Stopwatch.StartNew();

                var result = await _httpClient.GetFromJsonAsync<List<WeatherForecast>>("WeatherForecast");

                var messageBatch = await _serviceBusSender.CreateMessageBatchAsync();
                foreach (EventData eventData in events)
                {
                    var eventBody = eventData.EventBody.ToString();
                    var connectWrapper = JsonConvert.DeserializeObject<ConnectWrapper>(eventBody);

                    //TODO: Deserialize against Azure Schema Registry Here
                    var mongoAddress = JsonConvert.DeserializeObject<MongoAddress>(connectWrapper.Payload);

                    var sessionId = mongoAddress.ProfileId.Value;

                    log.LogInformation($"Processed Profile ID: {sessionId}");

                    var message = new ServiceBusMessage(eventBody) { SessionId = sessionId };

                    if (!messageBatch.TryAddMessage(message))
                    {
                        await _serviceBusSender.SendMessagesAsync(messageBatch);
                        messageBatch = await _serviceBusSender.CreateMessageBatchAsync();

                        if (!messageBatch.TryAddMessage(message))
                        {
                            throw new Exception("Event is too big for a new message batch");
                        }
                    }
                }

                if (DateTime.UtcNow.Millisecond.ToString().EndsWith("3"))
                {
                    throw new Exception("Random Exception from EhConsumer");
                }

                await _serviceBusSender.SendMessagesAsync(messageBatch);

                log.LogInformation($"Processed {events.Length} events in {sw.ElapsedMilliseconds}ms");

            }
            catch (Exception e)
            {
                // We need to keep processing the rest of the batch - capture this exception and continue.
                // Also, consider capturing details of the message that failed processing so it can be processed again later.
                exceptions.Add(e);
            }

            // Once processing of the batch is complete, if any messages in the batch failed processing throw an exception so that there is a record of the failure.
            if (exceptions.Count > 1)
                throw new AggregateException(exceptions);

            if (exceptions.Count == 1)
                throw exceptions.Single();
        }
    }
}
