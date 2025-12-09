@description('Storage account name')
param storageAccountName string

@description('Cosmos DB account name')
param cosmosDbAccountName string

@description('Search service name')
param searchServiceName string

@description('Blobstore container name')
param blobstoreContainerName string

@description('Agents blobstore container name')
param agentsBlobstoreContainerName string

@description('Managed identity principal ID')
param managedIdentityPrincipalId string

@description('AI Project principal ID')
param aiProjectPrincipalId string

// ===== EXISTING RESOURCE REFERENCES =====

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' existing = {
  name: cosmosDbAccountName
}

resource searchService 'Microsoft.Search/searchServices@2024-03-01-preview' existing = {
  name: searchServiceName
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' existing = {
  parent: storageAccount
  name: 'default'
}

resource blobstoreContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' existing = {
  parent: blobService
  name: blobstoreContainerName
}

resource agentsBlobstoreContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' existing = {
  parent: blobService
  name: agentsBlobstoreContainerName
}

resource cosmosDbSqlRoleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2024-05-15' existing = {
  parent: cosmosDbAccount
  name: '00000000-0000-0000-0000-000000000002' // Built-in Data Contributor role
}

// ===== FUNCTION APP MANAGED IDENTITY ROLE ASSIGNMENTS =====

// Storage Queue Data Contributor
resource queueRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentityPrincipalId, 'StorageQueueDataContributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
    )
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Blob Data Contributor (for function storage)
resource blobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentityPrincipalId, 'StorageBlobDataContributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    )
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Table Data Contributor (for function storage)
resource tableRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentityPrincipalId, 'StorageTableDataContributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
    )
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ===== AI PROJECT ROLE ASSIGNMENTS =====

// Storage Queue Data Contributor for AI Project
resource aiProjectQueueRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, aiProjectPrincipalId, 'StorageQueueDataContributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
    )
    principalId: aiProjectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Cosmos DB Operator (Account-level) - System Managed Identity
resource projectCosmosOperatorRoleSMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosDbAccount.id, aiProjectPrincipalId, 'CosmosOperator-SMI')
  scope: cosmosDbAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '230815da-be43-4aae-9cb4-875f7bd000aa'
    )
    principalId: aiProjectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Cosmos DB Operator (Account-level) - User Managed Identity
resource projectCosmosOperatorRoleUMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cosmosDbAccount.id, managedIdentityPrincipalId, 'CosmosOperator-UMI')
  scope: cosmosDbAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '230815da-be43-4aae-9cb4-875f7bd000aa'
    )
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Account Contributor - System Managed Identity
resource projectStorageContributorRoleSMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, aiProjectPrincipalId, 'StorageContributor-SMI')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '17d1049b-9a84-46fb-8f53-869881c3d3ab'
    )
    principalId: aiProjectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Account Contributor - User Managed Identity
resource projectStorageContributorRoleUMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentityPrincipalId, 'StorageContributor-UMI')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '17d1049b-9a84-46fb-8f53-869881c3d3ab'
    )
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Azure AI Search - Search Index Data Contributor - System Managed Identity
resource projectSearchIndexDataContributorSMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, aiProjectPrincipalId, 'SearchIndexDataContributor-SMI')
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
    )
    principalId: aiProjectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Azure AI Search - Search Index Data Contributor - User Managed Identity
resource projectSearchIndexDataContributorUMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, managedIdentityPrincipalId, 'SearchIndexDataContributor-UMI')
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
    )
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Azure AI Search - Search Service Contributor - System Managed Identity
resource projectSearchServiceContributorSMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, aiProjectPrincipalId, 'SearchServiceContributor-SMI')
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
    )
    principalId: aiProjectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Azure AI Search - Search Service Contributor - User Managed Identity
resource projectSearchServiceContributorUMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, managedIdentityPrincipalId, 'SearchServiceContributor-UMI')
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
    )
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Blob Data Contributor on azureml-blobstore - System Managed Identity
resource projectBlobstoreContributorSMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(blobstoreContainer.id, aiProjectPrincipalId, 'BlobDataContributor-SMI')
  scope: blobstoreContainer
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    )
    principalId: aiProjectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Blob Data Contributor on azureml-blobstore - User Managed Identity
resource projectBlobstoreContributorUMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(blobstoreContainer.id, managedIdentityPrincipalId, 'BlobDataContributor-UMI')
  scope: blobstoreContainer
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    )
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Blob Data Owner on agents-blobstore - System Managed Identity
resource projectAgentsBlobstoreOwnerSMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(agentsBlobstoreContainer.id, aiProjectPrincipalId, 'BlobDataOwner-SMI')
  scope: agentsBlobstoreContainer
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
    )
    principalId: aiProjectPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Storage Blob Data Owner on agents-blobstore - User Managed Identity
resource projectAgentsBlobstoreOwnerUMI 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(agentsBlobstoreContainer.id, managedIdentityPrincipalId, 'BlobDataOwner-UMI')
  scope: agentsBlobstoreContainer
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
    )
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Cosmos DB Built-in Data Contributor - System Managed Identity
resource projectCosmosDatabaseDataContributorSMI 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  parent: cosmosDbAccount
  name: guid(cosmosDbAccount.id, aiProjectPrincipalId, 'CosmosDBDataContributor-SMI')
  properties: {
    roleDefinitionId: cosmosDbSqlRoleDefinition.id
    principalId: aiProjectPrincipalId
    scope: cosmosDbAccount.id
  }
}

// Cosmos DB Built-in Data Contributor - User Managed Identity
resource projectCosmosDatabaseDataContributorUMI 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  parent: cosmosDbAccount
  name: guid(cosmosDbAccount.id, managedIdentityPrincipalId, 'CosmosDBDataContributor-UMI')
  properties: {
    roleDefinitionId: cosmosDbSqlRoleDefinition.id
    principalId: managedIdentityPrincipalId
    scope: cosmosDbAccount.id
  }
}
