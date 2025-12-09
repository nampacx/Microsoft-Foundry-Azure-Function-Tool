using Azure;
using Azure.AI.Agents.Persistent;
using Azure.Identity;
using Microsoft.Extensions.Configuration;
using System.Text.Json;
using OpenApi.Services;

// Load configuration from appsettings.json
IConfigurationRoot configuration = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .Build();

var projectEndpoint = configuration["ProjectEndpoint"];
var modelDeploymentName = configuration["ModelDeploymentName"];
var tenantId = configuration["TenantId"];
var openApiSpecUrl = configuration["OpenApiSpecUrl"];
var agentName = configuration["AgentName"];


// Validate configuration
if (string.IsNullOrEmpty(projectEndpoint) || string.IsNullOrEmpty(modelDeploymentName))
{
    Console.WriteLine("Error: Required configuration values are not set in appsettings.json.");
    Console.WriteLine("Please set: ProjectEndpoint, ModelDeploymentName");
    return;
}

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
var openApiTool = OpenApiToolFactory.CreateWeatherTool(openApiSpec);

// Initialize agent service
var agentService = new AgentService(configService.ProjectEndpoint!, configService.TenantId);

// Get or create agent
var agent = await agentService.GetOrCreateAgentAsync(agentName, configService.ModelDeploymentName!, openApiTool);

// Create thread and run agent
var thread = await agentService.CreateThreadAsync();
var run = await agentService.RunAgentAsync(thread, agent, "What's the weather in Seattle?");

// Display results
agentService.DisplayResults(thread, run);
