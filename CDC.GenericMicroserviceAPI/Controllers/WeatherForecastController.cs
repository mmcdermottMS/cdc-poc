/*using CDC.Domain;
using Microsoft.AspNetCore.Mvc;

namespace CDC.GenericMicroserviceAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class WeatherForecastController : ControllerBase
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;
        private static readonly string[] Summaries = new[]
        {
            "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
        };

        private readonly ILogger<WeatherForecastController> _logger;
        private readonly Random _random = new();

        public WeatherForecastController(ILogger<WeatherForecastController> logger, IConfiguration configuration)
        {
            _logger = logger;
            _httpClient = new HttpClient();
            _configuration = configuration;
        }

        [HttpGet(Name = "GetWeatherForecast")]
        public async Task<IEnumerable<WeatherForecast>> Get()
        {
            try 
            {
                //var apiCallResult = await _httpClient.GetAsync(_configuration["ExternalApiUri"]);
                //var apiCallResult = await _httpClient.GetAsync("http://api.contoso.com");
                _logger.LogInformation($"Successfully made API call to http://api.contoso.com");
            }
            catch (Exception ex)
            {
                return new List<WeatherForecast>() { new WeatherForecast() { Summary = ex.Message } };
            }            

            _logger.LogInformation("Sent some weather details");

            if (DateTime.UtcNow.Millisecond.ToString().EndsWith("7"))
            {
                throw new Exception("Random Exception from Weather Service");
            }

            //Fake syncrhonous processing delay between 100 and 200 ms
            Thread.Sleep(_random.Next(100, 200));

            var region = _configuration["Region"] ?? "Unknown";

            return Enumerable.Range(1, 5).Select(index => new WeatherForecast
            {
                Region = region,
                Date = DateTime.Now.AddDays(index),
                TemperatureC = Random.Shared.Next(-20, 55),
                Summary = Summaries[Random.Shared.Next(Summaries.Length)]
            })
            .ToArray();
        }
    }
}
*/