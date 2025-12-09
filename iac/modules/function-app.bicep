@description('Name of the Azure Function App')
param functionAppName string

@description('Location for the resource')
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

@description('Storage account name')
param storageAccountName string

@description('Managed identity client ID')
param managedIdentityClientId string

@description('Managed identity resource ID')
param managedIdentityId string

@description('Array of queue names')
param queueNames array

var functionWorkerRuntime = runtime
var hostingPlanName = 'plan-${functionAppName}'
var applicationInsightsName = 'appi-${functionAppName}'

// Application Insights
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
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccountName
        }
        {
          name: 'AzureWebJobsStorage__credential'
          value: 'managedidentity'
        }
        {
          name: 'AzureWebJobsStorage__clientId'
          value: managedIdentityClientId
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

output functionAppId string = functionApp.id
output functionAppName string = functionApp.name
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
