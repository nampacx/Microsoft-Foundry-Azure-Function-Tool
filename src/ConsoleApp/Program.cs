using Azure;
using Azure.AI.Agents.Persistent;
using Azure.Identity;
using Microsoft.Extensions.Configuration;
using System.Text.Json;

// Load configuration from appsettings.json
IConfigurationRoot configuration = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .Build();

var projectEndpoint = configuration["ProjectEndpoint"];
var modelDeploymentName = configuration["ModelDeploymentName"];
var storageQueueUri = configuration["StorageQueueUri"];
var tenantId = configuration["TenantId"];

// Validate configuration
if (string.IsNullOrEmpty(projectEndpoint) || string.IsNullOrEmpty(modelDeploymentName) || string.IsNullOrEmpty(storageQueueUri))
{
    Console.WriteLine("Error: Required configuration values are not set in appsettings.json.");
    Console.WriteLine("Please set: ProjectEndpoint, ModelDeploymentName, StorageQueueUri, TenantId");
    return;
}

Console.WriteLine("Initializing Persistent Agents Client...");
var credentialOptions = new DefaultAzureCredentialOptions();
if (!string.IsNullOrEmpty(tenantId))
{
    credentialOptions.TenantId = tenantId;
}
PersistentAgentsClient client = new(projectEndpoint, new DefaultAzureCredential(credentialOptions));

// Define Azure Function Tool for Weather Service
AzureFunctionToolDefinition weatherServiceTool = new(
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
                Required = new[] { "Location", "CorrelationId" }
            },
        new JsonSerializerOptions() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase }
    )
);

Console.WriteLine("Creating persistent agent...");
PersistentAgent agent = client.Administration.CreateAgent(
    model: modelDeploymentName,
    name: "weather-assistant-agent",
        instructions: "You are a helpful weather assistant. When users ask about weather in a location, "
        + "use the get_weather function to retrieve current weather information. "
        + "Always generate a unique CorrelationId (GUID format) for each weather request. "
        + "Present the temperature information in a friendly and conversational way.",
    tools: [ weatherServiceTool ]
    );

Console.WriteLine($"Agent created: {agent.Id}");

Console.WriteLine("Creating thread...");
PersistentAgentThread thread = client.Threads.CreateThread();
Console.WriteLine($"Thread created: {thread.Id}");

Console.WriteLine("Creating message...");
client.Messages.CreateMessage(
    thread.Id,
    MessageRole.User,
    "What's the weather like in Berlin?");

Console.WriteLine("Running agent...");
ThreadRun run = client.Runs.CreateRun(thread.Id, agent.Id);

do
{
    Thread.Sleep(TimeSpan.FromMilliseconds(500));
    run = client.Runs.GetRun(thread.Id, run.Id);
    Console.WriteLine($"Run status: {run.Status}");
}
while (run.Status == RunStatus.Queued
    || run.Status == RunStatus.InProgress
    || run.Status == RunStatus.RequiresAction);

if (run.Status == RunStatus.Completed)
{
    Console.WriteLine("Run completed successfully!");
    
    // Get messages from the thread
    var messages = client.Messages.GetMessages(
        threadId: thread.Id,
        order: ListSortOrder.Ascending
    );
    
    foreach (var msg in messages)
    {
        Console.Write($"{msg.CreatedAt:yyyy-MM-dd HH:mm:ss} - {msg.Role,10}: ");
        foreach (var contentItem in msg.ContentItems)
        {
            if (contentItem is MessageTextContent textItem)
            {
                Console.WriteLine(textItem.Text);
            }
            else if (contentItem is MessageImageFileContent imageFileItem)
            {
                Console.WriteLine($"<image from ID: {imageFileItem.FileId}>");
            }
        }
    }
}
else
{
    Console.WriteLine($"Run failed with status: {run.Status}");
    if (run.LastError != null)
    {
        Console.WriteLine($"Error: {run.LastError.Message}");
    }
}
