namespace OpenApi.Services;

public class GroundingService
{
    private readonly string _dataFolderPath;

    public GroundingService(string? dataFolderPath = null)
    {
        _dataFolderPath = dataFolderPath ?? Path.Combine(AppContext.BaseDirectory, "Data");
        
        if (!Directory.Exists(_dataFolderPath))
        {
            Console.WriteLine($"Warning: Data folder does not exist at path: {_dataFolderPath}");
        }
    }

    public async Task<string?> ReadCvHtmlAsync()
    {
        var filePath = Path.Combine(_dataFolderPath, "cv.html");
        
        if (!File.Exists(filePath))
        {
            Console.WriteLine($"File not found: {filePath}");
            return null;
        }

        try
        {
            return await File.ReadAllTextAsync(filePath);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error reading file {filePath}: {ex.Message}");
            return null;
        }
    }

    public IEnumerable<string> GetAllDataFiles()
    {
        if (!Directory.Exists(_dataFolderPath))
        {
            return Enumerable.Empty<string>();
        }

        try
        {
            return Directory.GetFiles(_dataFolderPath, "*.*", SearchOption.AllDirectories)
                .Select(f => Path.GetRelativePath(_dataFolderPath, f));
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error retrieving files from {_dataFolderPath}: {ex.Message}");
            return Enumerable.Empty<string>();
        }
    }

    public async Task<Dictionary<string, string>> ReadAllDataFilesAsync()
    {
        var result = new Dictionary<string, string>();
        var files = GetAllDataFiles();

        foreach (var file in files)
        {
            var fullPath = Path.Combine(_dataFolderPath, file);
            try
            {
                var content = await File.ReadAllTextAsync(fullPath);
                result[file] = content;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error reading file {fullPath}: {ex.Message}");
            }
        }

        return result;
    }
}
