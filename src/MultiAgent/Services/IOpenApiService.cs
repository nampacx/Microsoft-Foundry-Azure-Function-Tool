namespace MultiAgent.Services;

public interface IOpenApiService
{
    Task<byte[]> DownloadOpenApiSpecAsync(string openApiSpecUrl);
}