using Azure.AI.Agents.Persistent;

namespace ConsoleApp.Services;

public interface IAgentService
{
    Task<PersistentAgent> CreateAgentAsync(string modelDeploymentName, AzureFunctionToolDefinition weatherTool);
    Task<PersistentAgentThread> CreateThreadAsync();
    Task<ThreadRun> RunAgentAsync(PersistentAgentThread thread, PersistentAgent agent, string userMessage);
    void DisplayResults(PersistentAgentThread thread, ThreadRun run);
}