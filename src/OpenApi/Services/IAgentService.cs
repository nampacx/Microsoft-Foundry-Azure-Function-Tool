using Azure.AI.Agents.Persistent;

namespace OpenApi.Services;

public interface IAgentService
{
    Task<PersistentAgent> GetOrCreateAgentAsync(string agentName, string modelDeploymentName, OpenApiToolDefinition openApiTool);
    Task<PersistentAgentThread> CreateThreadAsync();
    Task<ThreadRun> RunAgentAsync(PersistentAgentThread thread, PersistentAgent agent, string userMessage);
    void DisplayResults(PersistentAgentThread thread, ThreadRun run);
}