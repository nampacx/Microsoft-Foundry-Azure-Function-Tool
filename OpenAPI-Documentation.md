# OpenAPI/Swagger Documentation

Your Azure Function project now includes OpenAPI 3.0 and Swagger documentation support!

## Available Endpoints

Once you start the function app with `func start`, the following documentation endpoints are automatically available:

### Swagger UI (Interactive Documentation)
```
http://localhost:7071/api/swagger/ui
```
This provides an interactive web interface where you can explore and test your API endpoints.

### OpenAPI Document (JSON)
```
http://localhost:7071/api/openapi/v3.json
```
Returns the OpenAPI 3.0 specification in JSON format.

### OpenAPI Document (YAML)
```
http://localhost:7071/api/openapi/v3.yaml
```
Returns the OpenAPI 3.0 specification in YAML format.

### Swagger Document (JSON)
```
http://localhost:7071/api/swagger.json
```
Returns the Swagger specification in JSON format.

### OAuth2 Redirect Page
```
http://localhost:7071/api/oauth2-redirect.html
```
OAuth2 redirect handler for authentication flows.

## What Was Added

1. **NuGet Package**: `Microsoft.Azure.Functions.Worker.Extensions.OpenApi` (v1.5.1)
   - This package automatically generates OpenAPI/Swagger documentation for your Azure Functions

2. **Program.cs Configuration**: Added `.ConfigureOpenApi()` to enable OpenAPI support

3. **Automatic Documentation**: The OpenAPI extension automatically:
   - Discovers all HTTP trigger functions
   - Generates API documentation
   - Creates Swagger UI
   - Exposes OpenAPI specification endpoints

## Next Steps - Enhancing Documentation

You can enhance your function documentation by adding OpenAPI attributes. Here's an example:

```csharp
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.OpenApi.Models;
using System.Net;

[Function("Function1")]
[OpenApiOperation(operationId: "Run", tags: new[] { "greeting" })]
[OpenApiParameter(name: "name", In = ParameterLocation.Query, Required = false, Type = typeof(string), Description = "The name parameter")]
[OpenApiResponseWithBody(statusCode: HttpStatusCode.OK, contentType: "text/plain", bodyType: typeof(string), Description = "The OK response")]
public IActionResult Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
{
    // Your function code
}
```

### Available Attributes:
- `[OpenApiOperation]` - Describes the operation
- `[OpenApiParameter]` - Describes input parameters
- `[OpenApiRequestBody]` - Describes request body
- `[OpenApiResponseWithBody]` - Describes response with body
- `[OpenApiResponseWithoutBody]` - Describes response without body
- `[OpenApiSecurity]` - Describes security requirements

## Production Deployment

When deploying to Azure, these endpoints will be available at:
```
https://your-function-app.azurewebsites.net/api/swagger/ui
https://your-function-app.azurewebsites.net/api/openapi/v3.json
```

## References

- [Microsoft.Azure.Functions.Worker.Extensions.OpenApi Documentation](https://github.com/Azure/azure-functions-openapi-extension)
- [OpenAPI Specification](https://swagger.io/specification/)
