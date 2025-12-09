using Microsoft.Extensions.Configuration;

namespace ConsoleApp.Services;

public class ConfigurationService : IConfigurationService
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
    public string? StorageQueueUri => _configuration["StorageQueueUri"];
    public string? TenantId => _configuration["TenantId"];

    public bool ValidateConfiguration()
    {
        if (string.IsNullOrEmpty(ProjectEndpoint) || string.IsNullOrEmpty(ModelDeploymentName) || string.IsNullOrEmpty(StorageQueueUri))
        {
            Console.WriteLine("Error: Required configuration values are not set in appsettings.json.");
            Console.WriteLine("Please set: ProjectEndpoint, ModelDeploymentName, StorageQueueUri, TenantId");
            return false;
        }
        return true;
    }
}