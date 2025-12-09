using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using System.Text.Json;

namespace FunctionApp;

public class WeatherRequest
{
    public required string Location { get; set; }
    public required string CorrelationId { get; set; }
}

public class ToolResponse
{
    public required string Value { get; set; }

    public required string CorrelationId { get; set; }
}

public class WeatherServiceQueue
{
    private readonly ILogger<WeatherServiceQueue> _logger;
    private static readonly Random _random = new Random();

    public WeatherServiceQueue(ILogger<WeatherServiceQueue> logger)
    {
        _logger = logger;
    }

    [Function("WeatherServiceQueue")]
    [QueueOutput("%QueueOutputName%", Connection = "AzureWebJobsStorage")]
    public ToolResponse Run([QueueTrigger("%QueueInputName%", Connection = "AzureWebJobsStorage")] WeatherRequest input)
    {
        _logger.LogInformation("Processing weather request for location: {Location} with CorrelationId: {CorrelationId}", input.Location, input.CorrelationId);

        // Generate random temperature between -15 and 45 degrees Celsius
        int temperature = _random.Next(-15, 46); // 46 because upper bound is exclusive

        _logger.LogInformation("Generated temperature for {Location}: {Temperature}°C", input.Location, temperature);


        var result = new
        {
            Location = input.Location,
            Temperature = temperature,
            Unit = "Celsius"
        };

        var response = new ToolResponse
        {
            Value = JsonSerializer.Serialize(result),
            CorrelationId = input.CorrelationId
        };

        return response;
    }
}