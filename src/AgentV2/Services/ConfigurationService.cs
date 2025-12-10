using Microsoft.Extensions.Configuration;

namespace OpenApiV2.Services;

public class ConfigurationService
{
    private readonly IConfigurationRoot _configuration;

    public ConfigurationService()
    {
        _configuration = new ConfigurationBuilder()
            .SetBasePath(AppContext.BaseDirectory)
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
            .Build();
    }

    public string? ProjectEndpoint => _configuration["ProjectEndpoint"];
    public string? ModelDeploymentName => _configuration["ModelDeploymentName"];
    public string? TenantId => _configuration["TenantId"];
    public string? OpenApiSpecUrl => _configuration["OpenApiSpecUrl"];

    public string? AgentName => _configuration["AgentName"];

    public bool ValidateConfiguration()
    {
        if (string.IsNullOrEmpty(ProjectEndpoint) || string.IsNullOrEmpty(ModelDeploymentName))
        {
            Console.WriteLine("Error: Required configuration values are not set in appsettings.json.");
            Console.WriteLine("Please set: ProjectEndpoint, ModelDeploymentName");
            return false;
        }
        return true;
    }
}