# Microsoft-Foundry-Azure-Function-Tool

This repository contains infrastructure as code and application code for the Microsoft Foundry Azure Function Tool.

## Repository Structure

### IAC Folder
Contains the infrastructure as code for deploying the Azure resources:

- **main.bicep**: Bicep template that deploys:
  - Azure Function App with consumption plan
  - Storage Account
  - Two storage queues: `tool-input` and `tool-output`
  - Application Insights for monitoring

- **deploy.ps1**: PowerShell script to deploy the infrastructure to Azure

#### Deployment Instructions

```powershell
cd iac
./deploy.ps1 -ResourceGroupName "rg-foundry-tool" -Location "eastus"
```

### src Folder
Contains the Visual Studio solution with two projects:

#### ConsoleApp
A simple Hello World console application.

```bash
cd src/ConsoleApp
dotnet run
```

#### FunctionApp
An Azure Function app with a storage queue-triggered function that listens to the `tool-input` queue.

**Local Development:**
1. Install [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
2. Start Azurite or use Azure Storage Emulator
3. Run the function:
```bash
cd src/FunctionApp
func start
```

**Build the Solution:**
```bash
cd src
dotnet build FoundryToolSolution.sln
```

## Prerequisites

- [.NET 8.0 SDK](https://dotnet.microsoft.com/download)
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps) (for deployment)
- [Azurite](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azurite) (for local storage emulation)