@description('Azure region for the Key Vault.')
param location string = resourceGroup().location

@description('Name of the Key Vault (3-24 lowercase alphanumeric characters and hyphens).')
@minLength(3)
@maxLength(24)
param keyVaultName string

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

var secretsMap = {
  webAuthAppClientId: webAuthAppClientId
  webAuthAppSecret: webAuthAppSecret
  apiAuthAppClientId: apiAuthAppClientId
  apiAuthAppSecret: apiAuthAppSecret
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    enabledForDeployment: false
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    publicNetworkAccess: 'Disabled'
  }
}

resource kvSecrets 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [for item in items(secretsMap): if (!empty(item.value)) {
  parent: keyVault
  name: item.key
  properties: {
    value: item.value
  }
}]

resource kvKeys 'Microsoft.KeyVault/vaults/keys@2023-07-01' = [for keyName in keyNames: {
  parent: keyVault
  name: keyName
  properties: {
    kty: 'RSA'
    keySize: 2048
    keyOps: [
      'encrypt'
      'decrypt'
    ]
  }
}]

var webClientIdUri = '${keyVault.properties.vaultUri}secrets/webAuthAppClientId'
var webClientSecretUri = '${keyVault.properties.vaultUri}secrets/webAuthAppSecret'
var apiClientIdUri = '${keyVault.properties.vaultUri}secrets/apiAuthAppClientId'
var apiClientSecretUri = '${keyVault.properties.vaultUri}secrets/apiAuthAppSecret'

@description('Resource ID of the Key Vault.')
output keyVaultId string = keyVault.id

@description('Name of the Key Vault.')
output keyVaultName string = keyVault.name

@description('Vault URI.')
output vaultUri string = keyVault.properties.vaultUri

@description('App Service Key Vault reference for Web Auth Client ID.')
output webAuthAppClientIdRef string = !empty(webAuthAppClientId) ? '@Microsoft.KeyVault(SecretUri=${webClientIdUri})' : ''

@description('App Service Key Vault reference for Web Auth Client Secret.')
output webAuthAppSecretRef string = !empty(webAuthAppSecret) ? '@Microsoft.KeyVault(SecretUri=${webClientSecretUri})' : ''

@description('App Service Key Vault reference for API Auth Client ID.')
output apiAuthAppClientIdRef string = !empty(apiAuthAppClientId) ? '@Microsoft.KeyVault(SecretUri=${apiClientIdUri})' : ''

@description('App Service Key Vault reference for API Auth Client Secret.')
output apiAuthAppSecretRef string = !empty(apiAuthAppSecret) ? '@Microsoft.KeyVault(SecretUri=${apiClientSecretUri})' : ''

@description('Map of all Key Vault secret reference strings.')
output secretReferences object = {
  webAuthAppClientId: !empty(webAuthAppClientId) ? '@Microsoft.KeyVault(SecretUri=${webClientIdUri})' : ''
  webAuthAppSecret: !empty(webAuthAppSecret) ? '@Microsoft.KeyVault(SecretUri=${webClientSecretUri})' : ''
  apiAuthAppClientId: !empty(apiAuthAppClientId) ? '@Microsoft.KeyVault(SecretUri=${apiClientIdUri})' : ''
  apiAuthAppSecret: !empty(apiAuthAppSecret) ? '@Microsoft.KeyVault(SecretUri=${apiClientSecretUri})' : ''
}
