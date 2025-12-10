// @description('Name of the AI Foundry account')
// param aiFoundryName string

// @description('Name of the AI Project')
// param projectName string

// @description('Name of the storage connection')
// param storageConnectionName string

// @description('Name of the search connection')
// param searchConnectionName string

// @description('Name of the Cosmos DB connection')
// param cosmosConnectionName string

// // Reference existing AI Foundry account
// resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-10-01-preview' existing = {
//   name: aiFoundryName
// }

// // Reference existing AI Project
// resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-10-01-preview' existing = {
//   parent: aiFoundry
//   name: projectName
// }

// // Account Capability Host (empty properties)
// resource accountCapabilityHost 'Microsoft.CognitiveServices/accounts/capabilityHosts@2025-10-01-preview' = {
//   name: 'accountCapHost'
//   parent: aiFoundry
//   properties: {}
// }

// // Project Capability Host with Azure Storage, AI Search connections
// resource projectCapabilityHost 'Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-10-01-preview' = {
//   name: 'projectCapHost'
//   parent: aiProject
//   properties: {
//     capabilityHostKind: 'Agents'
//     storageConnections: [
//       storageConnectionName
//     ]
//     vectorStoreConnections: [
//       searchConnectionName
//     ]
//     threadStorageConnections: [
//       cosmosConnectionName
//     ]
//   }
//   dependsOn: [
//     accountCapabilityHost
//   ]
// }
