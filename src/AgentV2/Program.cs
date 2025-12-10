

using Azure.AI.Agents.Persistent;
using Azure.AI.Projects;
using Azure.AI.Projects.OpenAI;
using Azure.Identity;
using OpenAI;
using OpenAI.Responses;
using OpenApiV2.Services;

#pragma warning disable OPENAI001

var configService = new ConfigurationService();
if (!configService.ValidateConfiguration())
{
    return;
}

var openApiService = new OpenApiService();
byte[] openApiSpec;
try
{
    openApiSpec = await openApiService.DownloadOpenApiSpecAsync(configService.OpenApiSpecUrl!);
}
catch (Exception)
{
    return;
}


var openApiTool = OpenApiToolFactory.CreateWeatherTool(openApiSpec);


var agentService = new AgentService(
    projectEndpoint: configService.ProjectEndpoint!,
    tenantId: configService.TenantId
    );

var agent = await agentService.GetOrCreateAgentAsync(configService.AgentName!, configService.ModelDeploymentName!, new[] { openApiTool });
var conversation = await agentService.CreateConversationAsync();

// Use the agent to generate a response
var  response = await agentService.RunAgentAsync(agent,conversation, "What is the weather like in Seattle?");

Console.WriteLine(response);