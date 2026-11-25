@description('Azure region for the Key Vault.')
param location string = resourceGroup().location

@description('Name of the Key Vault (3-24 lowercase alphanumeric characters and hyphens).')
@minLength(3)
@maxLength(24)
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

@description('Optional list of cryptographic key names to create in the Key Vault.')
param keyNames array = []

@description('Tags applied to the Key Vault.')
param tags object = {}

var rawSecrets = [
  {
    name: 'webAuthAppClientId'
    value: webAuthAppClientId
  }
  {
    name: 'webAuthAppSecret'
    value: webAuthAppSecret
  }
  {
    name: 'apiAuthAppClientId'
    value: apiAuthAppClientId
  }
  {
    name: 'apiAuthAppSecret'
    value: apiAuthAppSecret
  }
]

var secretsToDeploy = filter(rawSecrets, s => !empty(s.value))

var keysToDeploy = [for keyName in keyNames: {
  name: keyName
  kty: 'RSA'
  keySize: 2048
  keyOps: [
    'encrypt'
    'decrypt'
  ]
}]

module keyVaultAvm 'br/public:avm/res/key-vault/vault:0.11.1' = {
  name: 'avm-kv-${keyVaultName}'
  params: {
    name: keyVaultName
    location: location
    tags: tags
    sku: skuName
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection
    publicNetworkAccess: publicNetworkAccess
    secrets: secretsToDeploy
    keys: !empty(keysToDeploy) ? keysToDeploy : null
  }
}

@description('Resource ID of the Key Vault.')
output keyVaultId string = keyVaultAvm.outputs.resourceId

@description('Name of the Key Vault.')
output keyVaultName string = keyVaultAvm.outputs.name

@description('Vault URI of the Key Vault.')
output vaultUri string = keyVaultAvm.outputs.uri

@description('App Service Key Vault reference for Web Auth Client ID.')
output webAuthAppClientIdRef string = !empty(webAuthAppClientId) ? '@Microsoft.KeyVault(SecretUri=${keyVaultAvm.outputs.uri}secrets/webAuthAppClientId)' : ''

@description('App Service Key Vault reference for Web Auth Client Secret.')
output webAuthAppSecretRef string = !empty(webAuthAppSecret) ? '@Microsoft.KeyVault(SecretUri=${keyVaultAvm.outputs.uri}secrets/webAuthAppSecret)' : ''

@description('App Service Key Vault reference for API Auth Client ID.')
output apiAuthAppClientIdRef string = !empty(apiAuthAppClientId) ? '@Microsoft.KeyVault(SecretUri=${keyVaultAvm.outputs.uri}secrets/apiAuthAppClientId)' : ''

@description('App Service Key Vault reference for API Auth Client Secret.')
output apiAuthAppSecretRef string = !empty(apiAuthAppSecret) ? '@Microsoft.KeyVault(SecretUri=${keyVaultAvm.outputs.uri}secrets/apiAuthAppSecret)' : ''

@description('Map of all Key Vault secret reference strings.')
output secretReferences object = {
  webAuthAppClientId: !empty(webAuthAppClientId) ? '@Microsoft.KeyVault(SecretUri=${keyVaultAvm.outputs.uri}secrets/webAuthAppClientId)' : ''
  webAuthAppSecret: !empty(webAuthAppSecret) ? '@Microsoft.KeyVault(SecretUri=${keyVaultAvm.outputs.uri}secrets/webAuthAppSecret)' : ''
  apiAuthAppClientId: !empty(apiAuthAppClientId) ? '@Microsoft.KeyVault(SecretUri=${keyVaultAvm.outputs.uri}secrets/apiAuthAppClientId)' : ''
  apiAuthAppSecret: !empty(apiAuthAppSecret) ? '@Microsoft.KeyVault(SecretUri=${keyVaultAvm.outputs.uri}secrets/apiAuthAppSecret)' : ''
}
