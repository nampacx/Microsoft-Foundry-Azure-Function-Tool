# Microsoft Foundry Azure Function Tool

A comprehensive solution demonstrating how to integrate Azure Functions as tools with Azure AI Foundry agents. This repository showcases multiple patterns for building AI agents that can leverage custom tools running on Azure infrastructure.

## Overview

This project demonstrates how to create AI agents using Azure AI Foundry that can invoke custom tools implemented as Azure Functions. It includes infrastructure-as-code (IaC) templates, deployment scripts, and multiple sample implementations showing different integration patterns.

## Architecture

The solution consists of:

- **Azure Function App**: Hosts custom tool implementations (e.g., weather service) triggered via Azure Storage Queues
- **Azure AI Foundry**: Provides the AI agent runtime and model deployments
- **Azure Storage**: Queue-based communication between agents and function tools
- **Azure Cosmos DB**: Storage for agent state and conversation history
- **Azure Key Vault**: Secure credential management
- **Azure AI Search**: Optional search capabilities for RAG patterns

## Repository Structure

```
├── iac/                    # Infrastructure as Code (Bicep templates)
│   ├── main.bicep         # Main infrastructure template
│   ├── main.bicepparam    # Parameter file
│   └── modules/           # Modular Bicep components
├── deploy/                # Deployment scripts
│   ├── deploy-iac.ps1    # Infrastructure deployment
│   └── deploy-function.ps1 # Function app deployment
└── src/                   # Source code
    ├── FunctionApp/       # Azure Function implementation
    ├── FunctionTool/        # Queue-based agent example
    ├── MultiAgent/        # Multi-agent orchestration example
    ├── OpenApi/           # OpenAPI-based tool integration
    └── Shared/            # Shared services and utilities
```

## Projects

### FunctionApp
Azure Function (.NET 8 isolated) that implements custom tools:
- Queue-triggered functions for asynchronous tool execution
- OpenAPI documentation support
- Application Insights integration
- Sample weather service implementation

### FunctionTool
Demonstrates how to create an agent that uses Azure Storage Queues to communicate with function-based tools:
- Creates agents with custom tool definitions
- Submits tool execution requests to Azure queues
- Retrieves results asynchronously

### MultiAgent
Shows multi-agent orchestration patterns:
- Orchestrator agent coordinating multiple specialized agents
- Connected agent pattern
- Agent-to-agent communication

### OpenApi
Demonstrates OpenAPI-based tool integration:
- Downloads OpenAPI specifications
- Creates tools from OpenAPI definitions
- Enables agents to call external APIs

## Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [Azure Functions Core Tools](https://docs.microsoft.com/azure/azure-functions/functions-run-local)
- Azure subscription with necessary permissions
- PowerShell 7+

## Getting Started

### 1. Deploy Infrastructure

```powershell
cd deploy
./deploy-iac.ps1 -ResourceGroupName <your-rg-name> -Location <location>
```

This will deploy:
- Azure AI Foundry workspace and project
- Function App with App Service Plan
- Storage Account with queues
- Cosmos DB account
- Key Vault
- Required role assignments and managed identities

### 2. Deploy Function App

```powershell
./deploy-function.ps1 -ResourceGroupName <your-rg-name> -FunctionAppName <function-app-name>
```

### 3. Configure Applications

Update `appsettings.json` in each project with your Azure resources:

```json
{
    "ProjectEndpoint": "https://<your-project>.api.azureml.ms",
    "TenantId": "<tenant-id>",
    "ModelDeploymentName": "<model-name>",
    "AgentName": "<agent-name>",
    "OrchestratorAgentName" : "<orchestrator-agetn-name>",
    "StorageQueueUri": "https://<storage>.queue.core.windows.net/"
}
```

### 4. Run Sample Applications

```powershell
# Run queue-based agent
cd src/ConsoleApp
dotnet run

# Run multi-agent orchestration
cd src/MultiAgent
dotnet run

# Run OpenAPI integration
cd src/OpenApi
dotnet run
```

## Key Features

### Queue-Based Tool Integration
- Asynchronous tool execution via Azure Storage Queues
- Decoupled architecture for scalability
- Built-in retry and error handling

### OpenAPI Support
- Automatic tool generation from OpenAPI specifications
- RESTful API integration
- Standardized API documentation

### Multi-Agent Patterns
- Agent orchestration and coordination
- Specialized agent roles
- Connected agent communication

### Azure Integration
- Managed identity authentication
- Application Insights monitoring
- Secure configuration with Key Vault
- Scalable infrastructure with Bicep IaC

## Tool Implementation Pattern

The weather service demonstrates a typical tool implementation:

1. **Tool Definition**: Agent registers a tool with schema defining inputs/outputs
2. **Queue Message**: Agent sends tool execution request to input queue
3. **Function Trigger**: Azure Function processes queue message
4. **Execution**: Function performs business logic
5. **Response**: Result posted to output queue
6. **Agent Retrieval**: Agent polls output queue for results

## Configuration

Key configuration settings:

- `QueueInputName`: Input queue name (default: `tool-input`)
- `QueueOutputName`: Output queue name (default: `tool-output`)
- `AzureWebJobsStorage`: Storage account connection string
- `APPLICATIONINSIGHTS_CONNECTION_STRING`: Application Insights connection
- Model deployment names and endpoints

## Security

- Uses Azure Managed Identity for authentication
- Secrets stored in Azure Key Vault
- Role-based access control (RBAC) for all resources
- Network security through private endpoints (optional)

## Monitoring

- Application Insights integration for telemetry
- Function execution logs
- Queue metrics and monitoring
- Agent conversation tracking

## Contributing

Contributions are welcome! Please ensure:
- Code follows existing patterns and conventions
- All tests pass
- Documentation is updated
- Bicep templates are validated

## License

See [LICENSE](LICENSE) file for details.

## Resources

- [Azure AI Foundry Documentation](https://learn.microsoft.com/azure/ai-studio/)
- [Azure Functions Documentation](https://learn.microsoft.com/azure/azure-functions/)
- [Azure OpenAI Service](https://learn.microsoft.com/azure/ai-services/openai/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)

## Support

For issues or questions:
- Open an issue in this repository
- Review existing documentation
- Check Azure service health status
