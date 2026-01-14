using Azure.AI.Agents.Persistent;
using OpenApi.Services;

// Initialize services
var configService = new ConfigurationService();
if (!configService.ValidateConfiguration())
{
    return;
}

Console.WriteLine("=== Agent Deployment System ===\n");

// Initialize agent definition service
var agentDefinitionService = new AgentDefinitionService("agents.yaml");

// Initialize orchestration service with proper disposal
using var openApiService = new OpenApiService();
var orchestrationService = new AgentOrchestrationService(
    configService.ProjectEndpoint!,
    configService.TenantId,
    agentDefinitionService,
    openApiService
);

// Create all agents from definitions (parsing and validation handled internally)
Dictionary<string, PersistentAgent> createdAgents;

try
{
    createdAgents = await orchestrationService.CreateAllAgentsAsync();
}
catch (Exception ex)
{
    Console.WriteLine($"✗ Error: {ex.Message}");
    return;
}

// Create thread and run agent
var thread = await orchestrationService.CreateThreadAsync();
var run = await orchestrationService.RunAgentAsync(thread, createdAgents.First().Value, "How is the weather in Berlin?");
orchestrationService.DisplayResults(thread, run);