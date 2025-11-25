using Microsoft.Extensions.Configuration;

namespace OpenApi.Services;

public interface IConfigurationService
{
    string? ProjectEndpoint { get; }
    string? ModelDeploymentName { get; }
    string? TenantId { get; }
    string? OpenApiSpecUrl { get; }
    bool ValidateConfiguration();
}