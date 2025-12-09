// ===== PARAMETERS =====

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

// ===== VARIABLES =====

var managedIdentityName = 'id-${functionAppName}'
var cosmosDbDatabaseName = 'enterprise_memory'
var workspaceId = toLower(projectName)

// ===== MODULES =====

// Managed Identity Module
module managedIdentity './modules/managed-identity.bicep' = {
  name: 'managedIdentity-deployment'
  params: {
    managedIdentityName: managedIdentityName
    location: location
  }
}

// Storage Module
module storage './modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    storageAccountName: storageAccountName
    location: location
    queueNames: queueNames
    workspaceId: workspaceId
  }
}

// Cosmos DB Module
module cosmosDb './modules/cosmos-db.bicep' = {
  name: 'cosmosdb-deployment'
  params: {
    cosmosDbAccountName: cosmosDbAccountName
    location: location
    databaseName: cosmosDbDatabaseName
  }
}

// Azure AI Search Module
module aiSearch './modules/ai-search.bicep' = {
  name: 'aisearch-deployment'
  params: {
    searchServiceName: searchServiceName
    location: location
  }
}

// Key Vault Module
module keyVault './modules/key-vault.bicep' = {
  name: 'keyvault-deployment'
  params: {
    keyVaultName: keyVaultName
    location: location
  }
}

// Function App Module
module functionApp './modules/function-app.bicep' = {
  name: 'functionapp-deployment'
  params: {
    functionAppName: functionAppName
    location: location
    runtime: runtime
    storageAccountName: storage.outputs.storageAccountName
    managedIdentityClientId: managedIdentity.outputs.clientId
    managedIdentityId: managedIdentity.outputs.id
    queueNames: queueNames
  }
}

// AI Foundry Module (without capability hosts initially)
module aiFoundry './modules/ai-foundry.bicep' = {
  name: 'aifoundry-deployment'
  params: {
    aiFoundryName: aiFoundryName
    location: location
    projectName: projectName
    modelDeploymentName: modelDeploymentName
    modelSkuCapacity: modelSkuCapacity
    modelSkuName: modelSkuName
    modelName: modelName
    modelFormat: modelFormat
    managedIdentityId: managedIdentity.outputs.id
    storageAccountName: storage.outputs.storageAccountName
    storageAccountId: storage.outputs.storageAccountId
    blobstoreContainerName: storage.outputs.blobstoreContainerName
    searchServiceName: aiSearch.outputs.searchServiceName
    searchServiceId: aiSearch.outputs.searchServiceId
    cosmosDbEndpoint: cosmosDb.outputs.cosmosDbEndpoint
    cosmosDbAccountId: cosmosDb.outputs.cosmosDbAccountId
    cosmosDbDatabaseName: cosmosDb.outputs.databaseName
    deployCapabilityHosts: false
  }
}

// Role Assignments Module
module roleAssignments './modules/role-assignments.bicep' = {
  name: 'roleassignments-deployment'
  params: {
    storageAccountName: storage.outputs.storageAccountName
    cosmosDbAccountName: cosmosDb.outputs.cosmosDbAccountName
    searchServiceName: aiSearch.outputs.searchServiceName
    blobstoreContainerName: storage.outputs.blobstoreContainerName
    agentsBlobstoreContainerName: storage.outputs.agentsBlobstoreContainerName
    managedIdentityPrincipalId: managedIdentity.outputs.principalId
    aiProjectPrincipalId: aiFoundry.outputs.aiProjectPrincipalId
  }
  dependsOn: [
    aiFoundry
  ]
}

// AI Foundry Capability Hosts Module (deployed after role assignments)
module aiFoundryCapabilityHosts './modules/ai-foundry-capability-hosts.bicep' = {
  name: 'aifoundry-capabilityhosts-deployment'
  params: {
    aiFoundryName: aiFoundry.outputs.aiFoundryName
    projectName: aiFoundry.outputs.aiProjectName
    storageConnectionName: 'storage-connection'
    searchConnectionName: 'search-connection'
  }
  dependsOn: [
    roleAssignments
  ]
}

// ===== OUTPUTS =====

output functionAppName string = functionApp.outputs.functionAppName
output storageAccountName string = storage.outputs.storageAccountName
output queueNames array = storage.outputs.queueNames
output managedIdentityId string = managedIdentity.outputs.id
output managedIdentityClientId string = managedIdentity.outputs.clientId
output aiFoundryName string = aiFoundry.outputs.aiFoundryName
output aiFoundryEndpoint string = aiFoundry.outputs.aiFoundryEndpoint
output aiProjectName string = aiFoundry.outputs.aiProjectName
output modelDeploymentName string = aiFoundry.outputs.modelDeploymentName
output cosmosDbAccountName string = cosmosDb.outputs.cosmosDbAccountName
output cosmosDbEndpoint string = cosmosDb.outputs.cosmosDbEndpoint
output searchServiceName string = aiSearch.outputs.searchServiceName
output searchServiceEndpoint string = aiSearch.outputs.searchServiceEndpoint
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
output blobstoreContainerName string = storage.outputs.blobstoreContainerName
output agentsBlobstoreContainerName string = storage.outputs.agentsBlobstoreContainerName
