using Azure.AI.Agents.Persistent;

namespace MultiAgent.Services;

public interface IAgentService
{
    Task<PersistentAgent> GetOrCreateAgentAsync(string agentName, string modelDeploymentName, ToolDefinition[]? tools = null);
    Task<PersistentAgentThread> CreateThreadAsync();
    Task<ThreadRun> RunAgentAsync(PersistentAgentThread thread, PersistentAgent agent, string userMessage);
    void DisplayResults(PersistentAgentThread thread, ThreadRun run);
}