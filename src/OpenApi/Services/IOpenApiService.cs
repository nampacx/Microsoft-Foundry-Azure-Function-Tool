namespace OpenApi.Services;

public interface IOpenApiService
{
    Task<byte[]> DownloadOpenApiSpecAsync(string openApiSpecUrl);
}