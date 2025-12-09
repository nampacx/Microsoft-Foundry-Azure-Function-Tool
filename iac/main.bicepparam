using './main.bicep'

// Parameters for Azure Function App and Foundry deployment
// Modify these values as needed for your deployment

// Function App parameters
param functionAppName = 'koko-agent-tool-func-app'
param runtime = 'dotnet-isolated'

param queueNames = [
  'tool-input'
  'tool-output'
]

// Foundry resources
param aiFoundryName = 'kk-fndry-ccnt'
param projectName = 'kk-prjct'

// Model deployment configuration
param modelDeploymentName = 'gpt-4o-mini-deployment'
param modelSkuCapacity = 200
param modelSkuName = 'GlobalStandard'
param modelName = 'gpt-4o-mini'
param modelFormat = 'OpenAI'

// Project-dependent resources
param storageAccountName = 'kkfndryagtendstorage'
param cosmosDbAccountName = 'kkfndryagtendcosmosdb'
param searchServiceName = 'kkfndryagtendsearch'
param keyVaultName = 'kkfndryagtendkeyvault'
