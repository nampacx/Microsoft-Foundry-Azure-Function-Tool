using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Extensions.OpenApi.Extensions;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Enums;
using Microsoft.Extensions.Logging;
using Microsoft.OpenApi.Models;
using System.Net;

namespace FunctionApp;

public class WeatherService
{
    private readonly ILogger<WeatherService> _logger;
    private static readonly Random _random = new Random();

    public WeatherService(ILogger<WeatherService> logger)
    {
        _logger = logger;
    }

    [Function("WeatherService")]
    [OpenApiOperation(operationId: "GetWeather", tags: new[] { "weather" }, Summary = "Get weather for a location", Description = "Returns a random temperature between -15°C and 45°C for the specified location")]
    [OpenApiParameter(name: "location", In = ParameterLocation.Query, Required = true, Type = typeof(string), Description = "The location to get weather for (e.g., Berlin, London, Paris)")]
    [OpenApiResponseWithBody(statusCode: HttpStatusCode.OK, contentType: "application/json", bodyType: typeof(WeatherResponse), Description = "Successfully retrieved weather data")]
    [OpenApiResponseWithBody(statusCode: HttpStatusCode.BadRequest, contentType: "application/json", bodyType: typeof(ErrorResponse), Description = "Missing or invalid location parameter")]
    public IActionResult Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequest req)
    {
        req.Headers.TryGetValue("Authorization", out var authHeader);

        // Get location parameter from query string or body
        string? location = req.Query["location"];
        
        if (string.IsNullOrEmpty(location))
        {
            return new BadRequestObjectResult(new { error = "Please provide a location parameter" });
        }

        // Generate random temperature between -15 and 45 degrees Celsius
        int temperature = _random.Next(-15, 46); // 46 because upper bound is exclusive

        var response = new
        {
            location = location,
            temperature = temperature,
            unit = "Celsius"
        };

        return new OkObjectResult(response);
    }
}

public class WeatherResponse
{
    public string Location { get; set; } = string.Empty;
    public int Temperature { get; set; }
    public string Unit { get; set; } = "Celsius";
}

public class ErrorResponse
{
    public string Error { get; set; } = string.Empty;
}