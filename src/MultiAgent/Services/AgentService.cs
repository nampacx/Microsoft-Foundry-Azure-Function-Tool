using Azure;
using Azure.AI.Agents.Persistent;
using Azure.Identity;

namespace MultiAgent.Services;

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

        var credentials = new DefaultAzureCredential(credentialOptions);
        _client = new PersistentAgentsClient(projectEndpoint, credentials);
    }

    public async Task<PersistentAgent> GetOrCreateAgentAsync(string agentName, string modelDeploymentName, OpenApiToolDefinition? openApiTool = null)
    {
        Console.WriteLine($"Checking if agent '{agentName}' already exists...");
        PersistentAgent? agent = null;

        try
        {
            var existingAgents = _client.Administration.GetAgents();
            foreach (var existingAgent in existingAgents)
            {
                if (existingAgent.Name == agentName)
                {
                    agent = existingAgent;
                    Console.WriteLine($"Found existing agent: {agent.Id}");
                    break;
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Warning: Error checking for existing agents: {ex.Message}");
        }

        if (agent == null)
        {
            Console.WriteLine("Creating new persistent agent...");
            var tools = openApiTool != null ? new[] { openApiTool } : null;
            agent = await _client.Administration.CreateAgentAsync(
                model: modelDeploymentName,
                name: agentName,
                instructions: "You are a helpful agent.",
                tools: tools
            );
            Console.WriteLine($"Agent created: {agent.Id}");
        }
        else
        {
            Console.WriteLine($"Using existing agent: {agent.Id}");
        }

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
        var run = (await _client.Runs.CreateRunAsync(thread, agent)).Value;

        do
        {
            await Task.Delay(TimeSpan.FromMilliseconds(5000));
            run = await _client.Runs.GetRunAsync(thread.Id, run.Id);
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