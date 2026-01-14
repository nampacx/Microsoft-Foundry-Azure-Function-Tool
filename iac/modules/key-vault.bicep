@description('Name of the Key Vault')
param keyVaultName string

@description('Location for the resource')
param location string = resourceGroup().location

// Generate a unique suffix based on resource group
var uniqueSuffix = uniqueString(resourceGroup().id)
var keyVaultNameCleaned = replace(keyVaultName, '-', '')
// Key Vault names must be 3-24 chars, uniqueString is 13 chars, so limit base name to 11 chars
var keyVaultBaseName = length(keyVaultNameCleaned) > 11 ? substring(keyVaultNameCleaned, 0, 11) : keyVaultNameCleaned
var keyVaultNameWithSuffix = '${keyVaultBaseName}${uniqueSuffix}'

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultNameWithSuffix
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

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
