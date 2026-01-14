using Microsoft.Extensions.Configuration;

namespace OpenApi.Services;

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
    public string? TenantId => _configuration["TenantId"];

    public bool ValidateConfiguration()
    {
        if (string.IsNullOrEmpty(ProjectEndpoint))
        {
            Console.WriteLine("Error: Required configuration values are not set in appsettings.json.");
            Console.WriteLine("Please set: ProjectEndpoint");
            return false;
        }
        return true;
    }
}