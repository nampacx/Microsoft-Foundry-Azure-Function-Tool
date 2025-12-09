namespace MultiAgent.Services;

public class OpenApiService : IOpenApiService
{
    private readonly HttpClient _httpClient;

    public OpenApiService()
    {
        _httpClient = new HttpClient();
    }

    public async Task<byte[]> DownloadOpenApiSpecAsync(string openApiSpecUrl)
    {
        Console.WriteLine($"Downloading OpenAPI specification from: {openApiSpecUrl}");
        
        try
        {
            var openApiSpec = await _httpClient.GetByteArrayAsync(openApiSpecUrl);
            Console.WriteLine("OpenAPI specification downloaded successfully.");
            return openApiSpec;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: Failed to download OpenAPI specification: {ex.Message}");
            throw;
        }
    }
}