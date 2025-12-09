using MultiAgent.Services;
using OpenApi.Services;

// Initialize services
var configService = new ConfigurationService();
if (!configService.ValidateConfiguration())
{
    return;
}

var openApiService = new OpenApiService();

// Download OpenAPI specification
byte[] openApiSpec;
try
{
    openApiSpec = await openApiService.DownloadOpenApiSpecAsync(configService.OpenApiSpecUrl!);
}
catch (Exception)
{
    return;
}

// Create OpenAPI tool
var weatherTool= ToolFactory.CreateWeatherTool(openApiSpec);

// Initialize agent service
var agentService = new AgentService(configService.ProjectEndpoint!, configService.TenantId);

// Get or create agent
var weatherAgent = await agentService.GetOrCreateAgentAsync(configService.AgentName!, configService.ModelDeploymentName!, new[] { weatherTool });

var orechstratorAgent = await agentService.GetOrCreateAgentAsync(
    configService.OrchestratorAgentName!,
    configService.ModelDeploymentName!,
    new[] { ToolFactory.CreateConnectedAgentWeatherTool(weatherAgent) }
);

// Create thread and run agent
var thread = await agentService.CreateThreadAsync();
var run = await agentService.RunAgentAsync(thread, orechstratorAgent, "How is the weather in Seattle?");

// Display results
agentService.DisplayResults(thread, run);
