@description('Azure region for the Key Vault.')
param location string = resourceGroup().location

@description('Azure region for the Private Endpoint (must match the VNet/subnet region).')
param privateEndpointLocation string = location

@description('Naming seed for resources (e.g., finance-prod-01).')
param nameSeed string

@description('Name of the Key Vault.')
param keyVaultName string

@description('SKU name for Key Vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Enable Azure RBAC authorization.')
param enableRbacAuthorization bool = true

@description('Soft delete retention in days.')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Enable purge protection.')
param enablePurgeProtection bool = true

@description('Public network access setting.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Web App Entra ID Client ID.')
param webAuthAppClientId string = ''

@description('Web App Entra ID Client Secret.')
@secure()
param webAuthAppSecret string = ''

@description('API App Entra ID Client ID.')
param apiAuthAppClientId string = ''

@description('API App Entra ID Client Secret.')
@secure()
param apiAuthAppSecret string = ''

@description('Optional list of cryptographic key names.')
param keyNames array = []

@description('Subnet resource ID where the Private Endpoint NIC is attached.')
param peSubnetId string

@description('Virtual Network resource ID for Private DNS Zone link.')
param vnetId string

@description('Tags applied to Key Vault tier resources.')
param tags object = {}

var kvPeName = 'pe-kv-${nameSeed}'

module keyVault './keyVault.bicep' = {
  name: 'kv-${nameSeed}'
  params: {
    location: location
    keyVaultName: keyVaultName
    skuName: skuName
    enableRbacAuthorization: enableRbacAuthorization
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection
    publicNetworkAccess: publicNetworkAccess
    webAuthAppClientId: webAuthAppClientId
    webAuthAppSecret: webAuthAppSecret
    apiAuthAppClientId: apiAuthAppClientId
    apiAuthAppSecret: apiAuthAppSecret
    keyNames: keyNames
    tags: tags
  }
}

module kvDnsZone './privateDns.bicep' = {
  name: 'dns-kv-${nameSeed}'
  params: {
    dnsZoneName: 'privatelink.vaultcore.azure.net'
    vnetId: vnetId
    tags: tags
  }
}

module kvPrivateEndpoint './privateEndpoint.bicep' = {
  name: 'pe-kv-${nameSeed}'
  params: {
    location: privateEndpointLocation
    privateEndpointName: kvPeName
    subnetId: peSubnetId
    resourceId: keyVault.outputs.keyVaultId
    groupId: 'vault'
    dnsZoneId: kvDnsZone.outputs.privateDnsId
    tags: tags
  }
}

@description('Resource ID of the Key Vault.')
output keyVaultId string = keyVault.outputs.keyVaultId

@description('Name of the Key Vault.')
output keyVaultName string = keyVault.outputs.keyVaultName

@description('Vault URI of the Key Vault.')
output vaultUri string = keyVault.outputs.vaultUri

@description('App Service Key Vault reference for Web Auth Client ID.')
output webAuthAppClientIdRef string = keyVault.outputs.webAuthAppClientIdRef

@description('App Service Key Vault reference for Web Auth Client Secret.')
output webAuthAppSecretRef string = keyVault.outputs.webAuthAppSecretRef

@description('App Service Key Vault reference for API Auth Client ID.')
output apiAuthAppClientIdRef string = keyVault.outputs.apiAuthAppClientIdRef

@description('App Service Key Vault reference for API Auth Client Secret.')
output apiAuthAppSecretRef string = keyVault.outputs.apiAuthAppSecretRef

@description('Map of all Key Vault secret reference strings.')
output secretReferences object = keyVault.outputs.secretReferences
