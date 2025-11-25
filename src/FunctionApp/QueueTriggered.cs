using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace FunctionApp;

public class Response
{
    public required string Value { get; set; }
    public required string CorrelationId { get; set; }
}

public class Arguments
{
    public required string Name { get; set; }
    public required string CorrelationId { get; set; }
}

public class Foo
{
    private readonly ILogger<Foo> _logger;

    public Foo(ILogger<Foo> logger)
    {
        _logger = logger;
    }

    [Function("Foo")]
    [QueueOutput("%QueueOutputName%", Connection = "AzureWebJobsStorage")]
    public Response Run([QueueTrigger("%QueueInputName%", Connection = "AzureWebJobsStorage")] Arguments input)
    {
        _logger.LogInformation("Processing queue message for {Name} with CorrelationId: {CorrelationId}", input.Name, input.CorrelationId);

        var response = new Response
        {
            Value = $"Hello, {input.Name}! Welcome!",
            CorrelationId = input.CorrelationId
        };

        return response;
    }
}