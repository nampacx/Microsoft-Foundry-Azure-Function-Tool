using Azure;
using Azure.AI.Agents.Persistent;
using Azure.Identity;

namespace ConsoleApp.Services;

public class AgentService : IAgentService
{
    private readonly PersistentAgentsClient _client;

    public AgentService(string projectEndpoint, string? tenantId)
    {
        Console.WriteLine("Initializing Persistent Agents Client...");
        
        var credentialOptions = new DefaultAzureCredentialOptions();
        if (!string.IsNullOrEmpty(tenantId))
        {
            credentialOptions.TenantId = tenantId;
        }

        _client = new PersistentAgentsClient(projectEndpoint, new DefaultAzureCredential(credentialOptions));
    }

    public async Task<PersistentAgent> CreateAgentAsync(string modelDeploymentName, AzureFunctionToolDefinition weatherTool)
    {
        Console.WriteLine("Creating persistent agent...");
        var agentResponse = await _client.Administration.CreateAgentAsync(
            model: modelDeploymentName,
            name: "weather-assistant-agent",
            instructions: "You are a helpful weather assistant. When users ask about weather in a location, "
                + "use the get_weather function to retrieve current weather information. "
                + "Always generate a unique CorrelationId (GUID format) for each weather request. "
                + "Present the temperature information in a friendly and conversational way.",
            tools: [weatherTool]
        );

        var agent = agentResponse.Value;
        Console.WriteLine($"Agent created: {agent.Id}");
        return agent;
    }

    public async Task<PersistentAgentThread> CreateThreadAsync()
    {
        Console.WriteLine("Creating thread...");
        var thread = (await _client.Threads.CreateThreadAsync()).Value;
        Console.WriteLine($"Thread created: {thread.Id}");
        return thread;
    }

    public async Task<ThreadRun> RunAgentAsync(PersistentAgentThread thread, PersistentAgent agent, string userMessage)
    {
        Console.WriteLine("Creating message...");
        await _client.Messages.CreateMessageAsync(
            thread.Id,
            MessageRole.User,
            userMessage);

        Console.WriteLine("Running agent...");
        var run = (await _client.Runs.CreateRunAsync(thread.Id, agent.Id)).Value;

        do
        {
            await Task.Delay(TimeSpan.FromMilliseconds(1000));
            run = (await _client.Runs.GetRunAsync(thread.Id, run.Id)).Value;
            Console.WriteLine($"Run status: {run.Status}");
        }
        while (run.Status == RunStatus.Queued
            || run.Status == RunStatus.InProgress
            || run.Status == RunStatus.RequiresAction);

        return run;
    }

    public void DisplayResults(PersistentAgentThread thread, ThreadRun run)
    {
        if (run.Status == RunStatus.Completed)
        {
            Console.WriteLine("Run completed successfully!");

            // Get messages from the thread
            var messages = _client.Messages.GetMessages(
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
    }
}