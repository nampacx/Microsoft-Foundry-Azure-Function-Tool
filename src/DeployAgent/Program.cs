using DeployAgent.Services;

if (args.Length == 0)
{
    Console.WriteLine("Usage: DeployAgent <path-to-yaml-file>");
    Console.WriteLine("Example: DeployAgent agents.yaml");
    return 1;
}

var yamlFilePath = args[0];

if (!File.Exists(yamlFilePath))
{
    Console.WriteLine($"Error: YAML file not found: {yamlFilePath}");
    return 1;
}

// Initialize services
var configService = new ConfigurationService();
if (!configService.ValidateConfiguration())
{
    return 1;
}

Console.WriteLine("=== Agent Deployment System ===\n");
Console.WriteLine($"Using YAML file: {yamlFilePath}\n");

// Initialize agent definition service
var agentDefinitionService = new AgentDefinitionService(yamlFilePath);

// Initialize orchestration service with proper disposal
using var openApiService = new OpenApiService();
var orchestrationService = new AgentOrchestrationService(
    configService.ProjectEndpoint!,
    configService.TenantId,
    agentDefinitionService,
    openApiService
);

    // Create all agents from definitions
    try
    {
        var createdAgents = await orchestrationService.CreateAllAgentsAsync();
        Console.WriteLine($"\n=== Successfully deployed {createdAgents.Count} agent(s) ===");
        return 0;
    }
    catch (Exception ex)
    {
        Console.WriteLine($"✗ Error: {ex.Message}");
        return 1;
    }
