using Microsoft.AspNetCore.Mvc;

namespace CDC.GenericMicroserviceAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class KimController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<KimController> _logger;

        public KimController(ILogger<KimController> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
        }

        [HttpGet(Name = "GetKim")]
        public async Task<string> Get([FromQuery(Name = "delayMs")] int delayMs)
        {
            var region = _configuration["Region"] ?? "Unknown";

            Thread.Sleep(delayMs);

            return $"Delayed {delayMs}ms. KIM Service running in {region}";
        }
    }
}
