# Microsoft Foundry Azure Deployment Guide

This Bicep template creates a complete Microsoft Foundry setup with all project-dependent resources.

## Resources Created

### Core Foundry Resources
- **Microsoft Foundry Account** (Cognitive Services - AIServices kind)
- **AI Project** (Cognitive Services Project)
- **Model Deployment** (gpt-4o or other agent-compatible model)

### Project-Dependent Resources
- **Cosmos DB Account** with `enterprise_memory` database
- **Azure Storage Account** with blob containers:
  - `{workspaceId}-azureml-blobstore`
  - `{workspaceId}-agents-blobstore`
- **Azure AI Search Service**
- **Key Vault**
- **Application Insights** (optional)
- **Queue Storage** for function triggers

### Supporting Resources
- **Azure Function App** with managed identity
- **App Service Plan** (Consumption)
- **User Assigned Managed Identity**

## Connections Created

### Account-Level Connections
- Application Insights connection (if created)

### Project-Level Connections
- **Foundry Resource connection** (if existingFoundryResourceId provided)
- **Azure Storage connection** (AAD authentication)
- **Azure AI Search connection** (AAD authentication)
- **Cosmos DB connection** (AAD authentication)

## Capability Hosts

### Account Capability Host
- Created with empty properties section as specified

### Project Capability Host
- Kind: Agents
- Configured with:
  - Storage connections
  - Vector store connections (AI Search)

## Role Assignments

All role assignments are created for both System Managed Identity (SMI) and User Managed Identity (UMI):

### Project Managed Identity Roles

#### Cosmos DB
- **Cosmos DB Operator** (Account-level scope)
- **Cosmos DB Built-in Data Contributor** (Database-level scope for `enterprise_memory`)

#### Azure Storage
- **Storage Account Contributor** (Account-level scope)
- **Storage Blob Data Contributor** on `{workspaceId}-azureml-blobstore` container
- **Storage Blob Data Owner** on `{workspaceId}-agents-blobstore` container

#### Azure AI Search
- **Search Index Data Contributor**
- **Search Service Contributor**

#### Function App Storage
- **Storage Queue Data Contributor** (for queue triggers)
- **Storage Blob Data Contributor** (for function runtime)
- **Storage Table Data Contributor** (for function runtime)

## Parameters

### Required Parameters
```bicep
functionAppName          // Name of the Azure Function App
storageAccountName       // Name of the Storage Account for Foundry
aiFoundryName           // Name of the AI Foundry account
projectName             // Name of the AI Project
cosmosDbAccountName     // Name of the Cosmos DB account
searchServiceName       // Name of the Azure AI Search service
keyVaultName            // Name of the Key Vault
modelDeploymentName     // Name of the model deployment
```

### Optional Parameters
```bicep
location                      // Default: resourceGroup().location
runtime                       // Default: 'dotnet-isolated'
queueNames                    // Default: ['tool-input', 'tool-output']
modelSkuCapacity             // Default: 50
modelSkuName                 // Default: 'Standard'
modelName                    // Default: 'gpt-4o'
modelFormat                  // Default: 'OpenAI'
modelVersion                 // Default: '2024-08-06'
createApplicationInsights    // Default: true
existingFoundryResourceId    // Default: '' (empty = no connection)
```

## Deployment Instructions

### Prerequisites
- Azure CLI installed
- Bicep CLI installed
- Appropriate Azure permissions to create resources
- Valid Azure subscription

### Deploy using Azure CLI

1. **Login to Azure**
```powershell
az login
az account set --subscription <subscription-id>
```

2. **Create Resource Group** (if needed)
```powershell
az group create --name <resource-group-name> --location <location>
```

3. **Deploy the Bicep template**
```powershell
az deployment group create `
  --resource-group <resource-group-name> `
  --template-file main.bicep `
  --parameters main.bicepparam
```

Or with inline parameters:
```powershell
az deployment group create `
  --resource-group <resource-group-name> `
  --template-file main.bicep `
  --parameters functionAppName=my-func-app `
               storageAccountName=mystorage `
               aiFoundryName=my-foundry `
               projectName=my-project `
               cosmosDbAccountName=mycosmosdb `
               searchServiceName=mysearch `
               keyVaultName=mykeyvault
```

### Deploy using PowerShell Script

Use the provided deployment script:
```powershell
.\deploy\deploy-iac.ps1
```

## Post-Deployment

After deployment completes, you'll receive outputs including:
- Function App name
- Storage account name
- AI Foundry endpoint
- Cosmos DB endpoint
- Search service endpoint
- Key Vault URI
- Model deployment name
- Blob container names

## Important Notes

1. **Naming Constraints**: 
   - Storage account names must be lowercase, no hyphens, 3-24 characters
   - Cosmos DB, Search, and Key Vault names must be globally unique

2. **Model Availability**: Ensure the specified model (e.g., gpt-4o) is available in your target region

3. **Role Assignment Propagation**: Role assignments may take a few minutes to propagate

4. **Bicep Warning**: You may see a BCP318 warning about nullable Application Insights - this is expected and won't affect deployment

## Troubleshooting

### Resource Name Conflicts
If you encounter naming conflicts, ensure:
- Storage account names are globally unique
- Custom subdomain names for Foundry are unique
- Search service names are globally unique

### Permission Issues
Ensure your account has:
- Owner or User Access Administrator role to assign roles
- Contributor role to create resources

### Model Deployment Failures
- Verify model availability in your region
- Check quota limits for your subscription
- Ensure the model SKU capacity is within limits

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Microsoft Foundry                     │
│  ┌─────────────────────────────────────────────────┐   │
│  │         AI Foundry Account (AIServices)          │   │
│  │  • System & User Managed Identity                │   │
│  │  • Account Capability Host                       │   │
│  │  • Model Deployment (gpt-4o)                     │   │
│  │  • Connection to Application Insights            │   │
│  └────────────┬─────────────────────────────────────┘   │
│               │                                          │
│  ┌────────────▼─────────────────────────────────────┐   │
│  │              AI Project                          │   │
│  │  • System & User Managed Identity                │   │
│  │  • Project Capability Host (Agents)              │   │
│  │  • Connections:                                  │   │
│  │    - Azure Storage                               │   │
│  │    - Azure AI Search                             │   │
│  │    - Cosmos DB                                   │   │
│  │    - [Optional] Existing Foundry                 │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
            ┌─────────────┼─────────────┐
            │             │             │
    ┌───────▼──────┐ ┌───▼────┐ ┌─────▼────────┐
    │   Cosmos DB  │ │Storage │ │ AI Search    │
    │  enterprise_ │ │ Blobs  │ │              │
    │   memory     │ │Queues  │ │              │
    └──────────────┘ └────────┘ └──────────────┘
                          │
                    ┌─────▼──────┐
                    │  Function  │
                    │    App     │
                    └────────────┘
```

## Security Considerations

1. **Managed Identities**: All authentication uses Azure AD and Managed Identities
2. **RBAC**: Least-privilege role assignments are configured
3. **HTTPS Only**: All resources enforce HTTPS
4. **Key Vault**: Centralized secret management
5. **Soft Delete**: Key Vault has soft delete enabled (90 days retention)

## Next Steps

1. Deploy your Function App code
2. Configure additional project settings as needed
3. Test the agent functionality
4. Monitor using Application Insights (if enabled)
5. Review and adjust role assignments as needed
