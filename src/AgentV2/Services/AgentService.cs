using Azure;
using Azure.AI.Projects;
using Azure.AI.Projects.OpenAI;
using Azure.Identity;
using OpenAI.Responses;

#pragma warning disable OPENAI001

namespace OpenApiV2.Services;

public class AgentService
{
    private readonly AIProjectClient _projectClient;


    public AgentService(string projectEndpoint, string? tenantId)
    {
        Console.WriteLine("Initializing AI Project Client...");

        var credentialOptions = new DefaultAzureCredentialOptions();
        if (!string.IsNullOrEmpty(tenantId))
        {
            credentialOptions.TenantId = tenantId;
        }

        var credentials = new DefaultAzureCredential(credentialOptions);

        // Connect to your project using the endpoint from your project page
        // The AzureCliCredential will use your logged-in Azure CLI identity, make sure to run `az login` first
        _projectClient = new AIProjectClient(endpoint: new Uri(projectEndpoint!), tokenProvider: credentials);
    }

    public async Task<AgentReference> GetOrCreateAgentAsync(string agentName, string model, OpenAPIAgentTool[] openAPIAgentTools)
    {
        Console.WriteLine($"Checking if agent '{agentName}' already exists...");

        try
        {
            AgentRecord agentRecord = await _projectClient.Agents.GetAgentAsync(agentName);

            if (agentRecord != null)
            {
                Console.WriteLine($"Agent retrieved (name: {agentRecord.Name}, id: {agentRecord.Id})");
                return agentRecord;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"No agent found");
        }

        Console.WriteLine($"Creating agent '{agentName}'...");

        try
        {
            PromptAgentDefinition agentDefinition = new PromptAgentDefinition(model)
            {
                Instructions = "You are a helpful assistant.",
            };
            if (openAPIAgentTools != null)
            {
                foreach (var tool in openAPIAgentTools)
                {
                    agentDefinition.Tools.Add(tool);
                }
            }

            var agentVersionOptions = new AgentVersionCreationOptions(agentDefinition);

            var agentVersion = _projectClient.Agents.CreateAgentVersion(
                agentName: agentName,
                options: agentVersionOptions
            );

            Console.WriteLine($"Agent created (name: {agentVersion.Value.Name}, id: {agentVersion.Value.Id})");
            return agentVersion.Value;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error creating agent: {ex.Message}");
            throw;
        }
    }

    public async Task<ProjectConversation> CreateConversationAsync()
    {
        Console.WriteLine("Creating conversation...");
        var conversation = await _projectClient.OpenAI.Conversations.CreateProjectConversationAsync();
        Console.WriteLine($"Conversation created: {conversation.Value.Id}");
        return conversation.Value;
    }

    public async Task<string> RunAgentAsync(AgentReference agentVersion, ProjectConversation conversation, string userMessage)
    {
        Console.WriteLine("Running agent with user message...");

        try
        {
            OpenAIResponseClient responseClient = _projectClient.OpenAI.GetProjectResponsesClientForAgent(
                agentVersion,
                conversation.Id
            );

            // Send the user message and get response
            OpenAIResponse response = responseClient.CreateResponse(userMessage);

            Console.WriteLine("Agent completed successfully!");
            return response.GetOutputText();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error running agent: {ex.Message}");
            throw;
        }
    }

    public void DisplayResults(string response)
    {
        Console.WriteLine("Agent Response:");
        Console.WriteLine("=" + new string('=', 50));
        Console.WriteLine(response);
        Console.WriteLine("=" + new string('=', 50));
    }
}