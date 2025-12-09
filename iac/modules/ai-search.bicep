@description('Name of the Azure AI Search service')
param searchServiceName string

@description('Location for the resource')
param location string = resourceGroup().location

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

output searchServiceId string = searchService.id
output searchServiceName string = searchService.name
output searchServiceEndpoint string = 'https://${searchService.name}.search.windows.net'
