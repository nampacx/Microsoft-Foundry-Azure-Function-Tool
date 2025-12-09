@description('Name of the Storage Account')
param storageAccountName string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Array of queue names to create')
param queueNames array

@description('Workspace ID for container naming')
param workspaceId string

var storageAccountNameCleaned = toLower(replace(storageAccountName, '-', ''))

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

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output blobstoreContainerId string = blobstoreContainer.id
output blobstoreContainerName string = blobstoreContainer.name
output agentsBlobstoreContainerId string = agentsBlobstoreContainer.id
output agentsBlobstoreContainerName string = agentsBlobstoreContainer.name
output queueNames array = [for (queueName, i) in queueNames: queues[i].name]
