using Azure;
using Azure.AI.Agents.Persistent;

namespace MultiAgent.Services;

public static class ToolFactory
{
    public static OpenApiToolDefinition CreateWeatherTool(byte[] openApiSpec)
    {
        Console.WriteLine("Creating OpenAPI tool definition...");

        var securitySchema = new OpenApiManagedSecurityScheme("apiKey");
        var key = new OpenApiManagedAuthDetails(securitySchema);

        var oaiAuth = new OpenApiAnonymousAuthDetails();
        return new OpenApiToolDefinition(
            name: "get_weather",
            description: "Retrieve weather information for a location",
            spec: BinaryData.FromBytes(openApiSpec),
            openApiAuthentication: oaiAuth,
            defaultParams: ["format"]
        );
    }

    public static ConnectedAgentToolDefinition CreateConnectedAgentWeatherTool(PersistentAgent weatherAgent)
    {
        Console.WriteLine("Creating Connected Agent tool definition...");

        return new ConnectedAgentToolDefinition(
            new ConnectedAgentDetails(
               id: weatherAgent.Id,
               name: weatherAgent.Name,
               description: "Gets the weather information for a specified location"
            )
        );
    }
}