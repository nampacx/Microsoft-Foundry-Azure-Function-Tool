@description('Name of the Azure Function App')
param functionAppName string

@description('Name of the Storage Account for Foundry')
param storageAccountName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('The language worker runtime to load in the function app')
@allowed([
  'dotnet'
  'dotnet-isolated'
  'node'
  'python'
  'java'
])
param runtime string = 'dotnet-isolated'

@description('Array of queue names to create')
param queueNames array = [
  'tool-input'
  'tool-output'
]

@description('Name of the AI Foundry account')
param aiFoundryName string

@description('Name of the AI Project')
param projectName string

@description('Name of the model deployment')
param modelDeploymentName string

@description('Model SKU capacity')
param modelSkuCapacity int

@description('Model SKU name')
param modelSkuName string

@description('Model name')
param modelName string

@description('Model format')
param modelFormat string

@description('Name of the Cosmos DB account')
param cosmosDbAccountName string

@description('Name of the Azure AI Search service')
param searchServiceName string

@description('Name of the Key Vault')
param keyVaultName string

var functionWorkerRuntime = runtime
var hostingPlanName = 'plan-${functionAppName}'
var applicationInsightsName = 'appi-${functionAppName}'
var storageAccountNameCleaned = toLower(replace(storageAccountName, '-', ''))
var managedIdentityName = 'id-${functionAppName}'
var cosmosDbDatabaseName = 'enterprise_memory'
var workspaceId = toLower(projectName)

// User Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
}

// Cosmos DB Account
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: cosmosDbAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
  }
}

// Cosmos DB Database
resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmosDbAccount
  name: cosmosDbDatabaseName
  properties: {
    resource: {
      id: cosmosDbDatabaseName
    }
  }
}

// Storage Account for Foundry
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountNameCleaned
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

// Blob Service
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

// Blob Containers for Foundry
resource blobstoreContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: '${workspaceId}-azureml-blobstore'
}

resource agentsBlobstoreContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: '${workspaceId}-agents-blobstore'
}

// Azure AI Search
resource searchService 'Microsoft.Search/searchServices@2024-03-01-preview' = {
  name: searchServiceName
  location: location
  sku: {
    name: 'standard'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'enabled'
    disableLocalAuth: false
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
  }
}

// Queue Service
resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

// Queues - created dynamically from queueNames array
resource queues 'Microsoft.Storage/storageAccounts/queueServices/queues@2023-01-01' = [
  for queueName in queueNames: {
    parent: queueService
    name: queueName
  }
]

// Application Insights (optional)
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

// App Service Plan - Consumption
resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

// Function App
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
        }
        {
          name: 'AzureWebJobsStorage__credential'
          value: 'managedidentity'
        }
        {
          name: 'AzureWebJobsStorage__clientId'
          value: managedIdentity.properties.clientId
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
        {
          name: 'QueueInputName'
          value: queueNames[0]
        }
        {
          name: 'QueueOutputName'
          value: queueNames[1]
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

// Role Assignment - Storage Queue Data Contributor
resource queueRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentity.id, 'StorageQueueDataContributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
    )
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Role Assignment - Storage Blob Data Contributor (for function storage)
resource blobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentity.id, 'StorageBlobDataContributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    )
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Role Assignment - Storage Table Data Contributor (for function storage)
resource tableRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentity.id, 'StorageTableDataContributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
    )
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// AI Foundry Account (Cognitive Service AIServices)
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-10-01-preview' = {
  name: aiFoundryName
  location: location
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  properties: {
    publicNetworkAccess: 'Enabled'
    allowProjectManagement: true
    customSubDomainName: aiFoundryName
    disableLocalAuth: true
  }
}

// Model Deployment (gpt-4o or other agent compatible model)
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-10-01-preview' = {
  parent: aiFoundry
  name: modelDeploymentName
  sku: {
    capacity: modelSkuCapacity
    name: modelSkuName
  }
  properties: {
    model: {
      name: modelName
      format: modelFormat
    }
  }
}

// AI Project (Cognitive Service Project)
resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-10-01-preview' = {
  name: projectName
  parent: aiFoundry
  location: location
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {}
}

// Project Connection to Azure Storage
resource projectStorageConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-10-01-preview' = {
  parent: aiProject
  name: 'storage-connection'
  properties: {
    category: 'AzureStorageAccount'
    target: 'https://${storageAccount.name}.blob.${environment().suffixes.storage}'
    authType: 'AAD'
    metadata: {
      ResourceId: storageAccount.id
      AccountName: storageAccount.name
      ContainerName: blobstoreContainer.name
    }
  }
}

// Project Connection to Azure AI Search
resource projectSearchConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-10-01-preview' = {
  parent: aiProject
  name: 'search-connection'
  properties: {
    category: 'CognitiveSearch'
    target: 'https://${searchService.name}.search.windows.net'
    authType: 'AAD'
    metadata: {
      ResourceId: searchService.id
    }
  }
}

// Project Connection to Cosmos DB
resource projectCosmosConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-10-01-preview' = {
  parent: aiProject
  name: 'cosmos-connection'
  properties: {
    category: 'CosmosDB'
    target: cosmosDbAccount.properties.documentEndpoint
    authType: 'AAD'
    metadata: {
      ResourceId: cosmosDbAccount.id
      DatabaseName: cosmosDbDatabaseName
    }
  }
}

// Account Capability Host (empty properties)
resource accountCapabilityHost 'Microsoft.CognitiveServices/accounts/capabilityHosts@2025-10-01-preview' = {
  name: 'accountCapHost'
  parent: aiFoundry
  properties: {}
}

// Project Capability Host with Cosmos DB, Azure Storage, AI Search connections
resource projectCapabilityHost 'Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-10-01-preview' = {
  name: 'projectCapHost'
  parent: aiProject
  properties: {
    capabilityHostKind: 'Agents'
    storageConnections: [
      projectStorageConnection.name
    ]
    vectorStoreConnections: [
      projectSearchConnection.name
    ]
  }
  dependsOn: [
    accountCapabilityHost
  ]
}

// Role Assignment - Storage Queue Data Contributor for AI Project
resource aiProjectQueueRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, aiProject.id, 'StorageQueueDataContributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
    )
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ===== PROJECT MANAGED IDENTITY ROLE ASSIGNMENTS =====

// 1. Cosmos DB Operator (Account-level) - System Managed Identity
resource projectCosmosOperatorRoleSMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosDbAccount.id, aiProject.id, 'CosmosOperator-SMI')
  scope: cosmosDbAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '230815da-be43-4aae-9cb4-875f7bd000aa'
    )
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// 1. Cosmos DB Operator (Account-level) - User Managed Identity
resource projectCosmosOperatorRoleUMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosDbAccount.id, managedIdentity.id, 'CosmosOperator-UMI')
  scope: cosmosDbAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '230815da-be43-4aae-9cb4-875f7bd000aa'
    )
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// 2. Storage Account Contributor (Account-level) - System Managed Identity
resource projectStorageContributorRoleSMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, aiProject.id, 'StorageContributor-SMI')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '17d1049b-9a84-46fb-8f53-869881c3d3ab'
    )
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// 2. Storage Account Contributor (Account-level) - User Managed Identity
resource projectStorageContributorRoleUMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentity.id, 'StorageContributor-UMI')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '17d1049b-9a84-46fb-8f53-869881c3d3ab'
    )
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// 3. Azure AI Search - Search Index Data Contributor - System Managed Identity
resource projectSearchIndexDataContributorSMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, aiProject.id, 'SearchIndexDataContributor-SMI')
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
    )
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// 3. Azure AI Search - Search Index Data Contributor - User Managed Identity
resource projectSearchIndexDataContributorUMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, managedIdentity.id, 'SearchIndexDataContributor-UMI')
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
    )
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// 4. Azure AI Search - Search Service Contributor - System Managed Identity
resource projectSearchServiceContributorSMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, aiProject.id, 'SearchServiceContributor-SMI')
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
    )
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// 4. Azure AI Search - Search Service Contributor - User Managed Identity
resource projectSearchServiceContributorUMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, managedIdentity.id, 'SearchServiceContributor-UMI')
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
    )
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// 5. Storage Blob Data Contributor on azureml-blobstore - System Managed Identity
resource projectBlobstoreContributorSMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(blobstoreContainer.id, aiProject.id, 'BlobDataContributor-SMI')
  scope: blobstoreContainer
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    )
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// 5. Storage Blob Data Contributor on azureml-blobstore - User Managed Identity
resource projectBlobstoreContributorUMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(blobstoreContainer.id, managedIdentity.id, 'BlobDataContributor-UMI')
  scope: blobstoreContainer
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    )
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// 6. Storage Blob Data Owner on agents-blobstore - System Managed Identity
resource projectAgentsBlobstoreOwnerSMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(agentsBlobstoreContainer.id, aiProject.id, 'BlobDataOwner-SMI')
  scope: agentsBlobstoreContainer
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
    )
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// 6. Storage Blob Data Owner on agents-blobstore - User Managed Identity
resource projectAgentsBlobstoreOwnerUMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(agentsBlobstoreContainer.id, managedIdentity.id, 'BlobDataOwner-UMI')
  scope: agentsBlobstoreContainer
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
    )
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// 7. Cosmos DB Built-in Data Contributor (Account-level) - System Managed Identity
// Note: Using the SQL Role Definition for Cosmos DB NoSQL
// Scope must be at account level, not database level, for Cosmos DB RBAC
resource cosmosDbSqlRoleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2024-05-15' existing = {
  parent: cosmosDbAccount
  name: '00000000-0000-0000-0000-000000000002' // Built-in Data Contributor role
}

resource projectCosmosDatabaseDataContributorSMI 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  parent: cosmosDbAccount
  name: guid(cosmosDbAccount.id, aiProject.id, 'CosmosDBDataContributor-SMI')
  properties: {
    roleDefinitionId: cosmosDbSqlRoleDefinition.id
    principalId: aiProject.identity.principalId
    scope: cosmosDbAccount.id
  }
}

// 7. Cosmos DB Built-in Data Contributor (Account-level) - User Managed Identity
resource projectCosmosDatabaseDataContributorUMI 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  parent: cosmosDbAccount
  name: guid(cosmosDbAccount.id, managedIdentity.id, 'CosmosDBDataContributor-UMI')
  properties: {
    roleDefinitionId: cosmosDbSqlRoleDefinition.id
    principalId: managedIdentity.properties.principalId
    scope: cosmosDbAccount.id
  }
}

// ===== OUTPUTS =====

output functionAppName string = functionApp.name
output storageAccountName string = storageAccount.name
output queueNames array = [for (queueName, i) in queueNames: queues[i].name]
output managedIdentityId string = managedIdentity.id
output managedIdentityClientId string = managedIdentity.properties.clientId
output aiFoundryName string = aiFoundry.name
output aiFoundryEndpoint string = aiFoundry.properties.endpoint
output aiProjectName string = aiProject.name
output modelDeploymentName string = modelDeployment.name
output cosmosDbAccountName string = cosmosDbAccount.name
output cosmosDbEndpoint string = cosmosDbAccount.properties.documentEndpoint
output searchServiceName string = searchService.name
output searchServiceEndpoint string = 'https://${searchService.name}.search.windows.net'
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output blobstoreContainerName string = blobstoreContainer.name
output agentsBlobstoreContainerName string = agentsBlobstoreContainer.name
