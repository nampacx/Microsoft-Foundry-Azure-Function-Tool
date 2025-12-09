namespace ConsoleApp.Services;

public interface IConfigurationService
{
    string? ProjectEndpoint { get; }
    string? ModelDeploymentName { get; }
    string? StorageQueueUri { get; }
    string? TenantId { get; }
    bool ValidateConfiguration();
}