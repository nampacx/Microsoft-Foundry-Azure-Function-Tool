using Azure;
using Azure.AI.Agents.Persistent;
using System.Text.Json;

namespace ConsoleApp.Services;

public static class ToolFactory
{
    public static AzureFunctionToolDefinition CreateWeatherTool(string storageQueueUri)
    {
        return new AzureFunctionToolDefinition(
            name: "get_weather",
            description: "Get current weather information for a specified location. Returns temperature in Celsius.",
            inputBinding: new AzureFunctionBinding(
                new AzureFunctionStorageQueue(
                    queueName: "tool-input",
                    storageServiceEndpoint: storageQueueUri
                )
            ),
            outputBinding: new AzureFunctionBinding(
                new AzureFunctionStorageQueue(
                    queueName: "tool-output",
                    storageServiceEndpoint: storageQueueUri
                )
            ),
            parameters: BinaryData.FromObjectAsJson(
                new
                {
                    Type = "object",
                    Properties = new
                    {
                        Location = new
                        {
                            Type = "string",
                            Description = "The location to get weather for (e.g., Berlin, London, Paris, Tokyo).",
                        },
                        CorrelationId = new
                        {
                            Type = "string",
                            Description = "Unique identifier for tracking the request."
                        }
                    },
                },
                new JsonSerializerOptions() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }
            )
        );
    }
}