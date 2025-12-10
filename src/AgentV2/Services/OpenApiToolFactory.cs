using Azure;
using Azure.AI.Agents.Persistent;
using Azure.AI.Projects.OpenAI;
using OpenAI.Responses;

namespace OpenApiV2.Services;

public static class OpenApiToolFactory
{
    public static OpenAPIAgentTool CreateWeatherTool(byte[] openApiSpec)
    {
        Console.WriteLine("Creating OpenAPI tool definition...");

        OpenAPIFunctionDefinition toolDefinition = new(
            name: "get_weather",
            spec: BinaryData.FromBytes(BinaryData.FromBytes(openApiSpec)),
            auth: new OpenAPIAnonymousAuthenticationDetails()
            );
        toolDefinition.Description = "Retrieve weather information for a location.";
        OpenAPIAgentTool openapiTool = new(toolDefinition);
        return openapiTool;
    }
}