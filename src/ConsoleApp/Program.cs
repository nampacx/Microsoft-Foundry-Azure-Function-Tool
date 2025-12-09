using ConsoleApp.Services;

// Initialize services
var configService = new ConfigurationService();
if (!configService.ValidateConfiguration())
{
    return;
}

// Create weather tool
var weatherTool = ToolFactory.CreateWeatherTool(configService.StorageQueueUri!);

// Initialize agent service
var agentService = new AgentService(configService.ProjectEndpoint!, configService.TenantId);

// Create agent
var agent = await agentService.CreateAgentAsync(configService.ModelDeploymentName!, weatherTool);

// Create thread and run agent
var thread = await agentService.CreateThreadAsync();
var run = await agentService.RunAgentAsync(thread, agent, "What's the weather like in Berlin?");

// Display results
agentService.DisplayResults(thread, run);
