@description('Name of the AI Foundry account')
param aiFoundryName string

@description('Location for the resource')
param location string = resourceGroup().location

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

@description('Managed identity resource ID')
param managedIdentityId string

@description('Storage account name')
param storageAccountName string

@description('Storage account ID')
param storageAccountId string

@description('Blobstore container name')
param blobstoreContainerName string

@description('Search service name')
param searchServiceName string

@description('Search service ID')
param searchServiceId string

@description('Cosmos DB account endpoint')
param cosmosDbEndpoint string

@description('Cosmos DB account ID')
param cosmosDbAccountId string

@description('Cosmos DB database name')
param cosmosDbDatabaseName string

@description('Whether to deploy capability hosts (should be false initially)')
param deployCapabilityHosts bool = true

// AI Foundry Account (Cognitive Service AIServices)
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-10-01-preview' = {
  name: aiFoundryName
  location: location
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
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
      '${managedIdentityId}': {}
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
    target: 'https://${storageAccountName}.blob.${environment().suffixes.storage}'
    authType: 'AAD'
    metadata: {
      ResourceId: storageAccountId
      AccountName: storageAccountName
      ContainerName: blobstoreContainerName
    }
  }
}

// Project Connection to Azure AI Search
resource projectSearchConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-10-01-preview' = {
  parent: aiProject
  name: 'search-connection'
  properties: {
    category: 'CognitiveSearch'
    target: 'https://${searchServiceName}.search.windows.net'
    authType: 'AAD'
    metadata: {
      ResourceId: searchServiceId
    }
  }
}

// Project Connection to Cosmos DB
resource projectCosmosConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-10-01-preview' = {
  parent: aiProject
  name: 'cosmos-connection'
  properties: {
    category: 'CosmosDB'
    target: cosmosDbEndpoint
    authType: 'AAD'
    metadata: {
      ResourceId: cosmosDbAccountId
      DatabaseName: cosmosDbDatabaseName
    }
  }
}

// Account Capability Host (empty properties) - Optional
resource accountCapabilityHost 'Microsoft.CognitiveServices/accounts/capabilityHosts@2025-10-01-preview' = if (deployCapabilityHosts) {
  name: 'accountCapHost'
  parent: aiFoundry
  properties: {}
  dependsOn: [
    modelDeployment
  ]
}

// Project Capability Host with Cosmos DB, Azure Storage, AI Search connections - Optional
resource projectCapabilityHost 'Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-10-01-preview' = if (deployCapabilityHosts) {
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
    projectCosmosConnection
  ]
}

output aiFoundryId string = aiFoundry.id
output aiFoundryName string = aiFoundry.name
output aiFoundryEndpoint string = aiFoundry.properties.endpoint
output aiProjectId string = aiProject.id
output aiProjectName string = aiProject.name
output aiProjectPrincipalId string = aiProject.identity.principalId
output modelDeploymentName string = modelDeployment.name
