using Azure;
using Azure.AI.Agents.Persistent;

namespace OpenApi.Services;

public static class OpenApiToolFactory
{
    public static OpenApiToolDefinition CreateWeatherTool(byte[] openApiSpec)
    {
        Console.WriteLine("Creating OpenAPI tool definition...");

        var securitySchema = new OpenApiManagedSecurityScheme("apiKey");
        var key = new OpenApiManagedAuthDetails(securitySchema);
       
        OpenApiConnectionAuthDetails


        var oaiAuth = new OpenApiAnonymousAuthDetails();
        return new OpenApiToolDefinition(
            name: "get_weather",
            description: "Retrieve weather information for a location",
            spec: BinaryData.FromBytes(openApiSpec),
            openApiAuthentication: oaiAuth,
            defaultParams: ["format"]
        );
    }
}