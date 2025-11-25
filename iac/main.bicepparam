using './main.bicep'

// Parameters for Azure Function App deployment
// Modify these values as needed for your deployment

// Leave commented to use auto-generated names based on resource group

param functionAppName = 'my-custom-func-app'
param storageAccountName = 'mkagentstorage'
param runtime = 'dotnet-isolated'

param queueNames = [
  'tool-input'
  'tool-output'
]

param aiFoundryName = 'ai-foundry-account'
param projectName = 'ai-project'
param modelDeploymentName = 'gpt-4o-deployment'
param modelSkuCapacity = 1
param modelSkuName = 'Standard'
param modelName = 'gpt-4o'
param modelFormat = 'OpenAI'
