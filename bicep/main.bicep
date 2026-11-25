targetScope = 'subscription'

metadata name = 'Corporate Workload Deployment Stack'
metadata description = 'Subscription-level deployment stack provisioning an end-to-end enterprise workload: Resource Group, Spoke VNet with Hub peering, Azure SQL with Entra ID authentication, Web & API App Services with Private Endpoints, Private DNS, and Key Vault.'

@description('Workload identifier (e.g., finance, hr, core).')
@minLength(2)
@maxLength(16)
param workload string = 'finance'

@description('Target environment name.')
@allowed([
  'dev'
  'test'
  'staging'
  'prod'
])
param environment string = 'prod'

@description('Azure region for deployment.')
param location string = 'centralus'

@description('Deployment stack name.')
param stackName string = 'stack-${workload}-${environment}'

@description('Instance index for naming disambiguation.')
@minValue(1)
@maxValue(99)
param instanceIndex int = 1

@description('Spoke VNet address space CIDR.')
param vnetAddressPrefix string = '10.1.0.0/16'

@description('Subnets configuration for spoke VNet.')
param subnets array = [
  {
    name: 'snet-web'
    addressPrefix: '10.1.1.0/24'
    delegation: 'Microsoft.Web/serverFarms'
  }
  {
    name: 'snet-api'
    addressPrefix: '10.1.2.0/24'
    delegation: 'Microsoft.Web/serverFarms'
  }
  {
    name: 'snet-pe'
    addressPrefix: '10.1.3.0/24'
  }
]

@description('Hub connectivity subscription ID.')
param hubSubscriptionId string = '7f493ff6-603b-4254-a6bf-e9acfc665866'

@description('Hub resource group name.')
param hubResourceGroupName string = 'rg-connectivity-hub-prod'

@description('Hub VNet name.')
param hubVnetName string = 'vnet-platform-connectivity-prod'

@description('App Service Plan SKU name (e.g., B1, S1, P1v3).')
param appServicePlanSku string = 'B1'

@description('SQL Database name.')
param sqlDatabaseName string = 'sqldb-${workload}-${environment}'

@description('Entra ID Admin Object ID for SQL Server.')
param sqlAdminObjectId string

@description('Entra ID Admin Login/Name for SQL Server.')
param sqlAdminLogin string

// ==========================================
// Key Vault Parameters (Commented out for now)
// ==========================================
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

@description('Optional Key Vault name override (must be globally unique, 3-24 chars).')
param keyVaultName string = ''

@description('Additional tags merged with baseline governance tags.')
param extraTags object = {}

param deployedAt string = utcNow('yyyy-MM-dd')

var paddedIndex = padLeft(string(instanceIndex), 2, '0')
var nameSeed = '${workload}-${environment}-${paddedIndex}'
var rgName = 'rg-${nameSeed}'
var planName = 'asp-${nameSeed}'
var webAppName = 'app-web-${nameSeed}'
var apiAppName = 'app-api-${nameSeed}'
var sqlServerName = 'sql-${nameSeed}'
var sqlPeName = 'pe-sql-${nameSeed}'
var apiPeName = 'pe-api-${nameSeed}'

// Key Vault names are max 24 chars and globally unique; append a deterministic suffix if not overridden
var uniqueSuffix = take(uniqueString(subscription().id, rgName), 5)
var resolvedKeyVaultName = !empty(keyVaultName) ? keyVaultName : take('kv-${workload}-${environment}-${paddedIndex}-${uniqueSuffix}', 24)

var hubVnetId = '/subscriptions/${hubSubscriptionId}/resourceGroups/${hubResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${hubVnetName}'

var baselineTags = union(extraTags, {
  workload: workload
  environment: environment
  managedBy: 'bicep-deployment-stack'
  costCenter: toLower('${workload}-${environment}')
  deployedAt: deployedAt
})

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: baselineTags
}

// ==========================================
// Key Vault & Related PE/DNS (Commented out)
// ==========================================
var kvPeName = 'pe-kv-${nameSeed}'

module kvDnsZone './modules/privateDns.bicep' = {
  name: 'dns-kv-${nameSeed}'
  scope: rg
  params: {
    dnsZoneName: 'privatelink.vaultcore.azure.net'
    vnetId: network.outputs.vnetId
    tags: baselineTags
  }
}

module kvPrivateEndpoint './modules/privateEndpoint.bicep' = {
  name: 'pe-kv-${nameSeed}'
  scope: rg
  params: {
    location: location
    privateEndpointName: kvPeName
    subnetId: peSubnetId
    resourceId: keyVaultModule.outputs.keyVaultId
    groupId: 'vault'
    dnsZoneId: kvDnsZone.outputs.privateDnsId
    tags: baselineTags
  }
}

module keyVaultModule './modules/keyVault.bicep' = {
  name: 'kv-${nameSeed}'
  scope: rg
  params: {
    location: location
    keyVaultName: resolvedKeyVaultName
    webAuthAppClientId: webAuthAppClientId
    webAuthAppSecret: webAuthAppSecret
    apiAuthAppClientId: apiAuthAppClientId
    apiAuthAppSecret: apiAuthAppSecret
    tags: baselineTags
  }
}

module network './modules/network.bicep' = {
  name: 'network-${nameSeed}'
  scope: rg
  params: {
    location: location
    nameSeed: nameSeed
    vnetAddressPrefix: vnetAddressPrefix
    subnets: subnets
    hubVnetId: hubVnetId
    hubVnetName: hubVnetName
    tags: baselineTags
  }
}

var webSubnetId = filter(network.outputs.subnets, s => s.name == 'snet-web')[0].id
var apiSubnetId = filter(network.outputs.subnets, s => s.name == 'snet-api')[0].id
var peSubnetId = filter(network.outputs.subnets, s => s.name == 'snet-pe')[0].id

module sqlDnsZone './modules/privateDns.bicep' = {
  name: 'dns-sql-${nameSeed}'
  scope: rg
  params: {
    dnsZoneName: 'privatelink${az.environment().suffixes.sqlServerHostname}'
    vnetId: network.outputs.vnetId
    tags: baselineTags
  }
}

module appServiceDnsZone './modules/privateDns.bicep' = {
  name: 'dns-app-${nameSeed}'
  scope: rg
  params: {
    dnsZoneName: 'privatelink.azurewebsites.net'
    vnetId: network.outputs.vnetId
    tags: baselineTags
  }
}

module planModule './modules/appServicePlan.bicep' = {
  name: 'plan-${nameSeed}'
  scope: rg
  params: {
    location: location
    planName: planName
    skuName: appServicePlanSku
    tags: baselineTags
  }
}

module sqlServerModule './modules/sqlServer.bicep' = {
  name: 'sqlsrv-${nameSeed}'
  scope: rg
  params: {
    location: location
    sqlServerName: sqlServerName
    sqlAdminObjectId: sqlAdminObjectId
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPrincipalType: 'Group'
    tags: baselineTags
  }
}

module databaseModule './modules/sqlDatabase.bicep' = {
  name: 'sqldb-${nameSeed}'
  scope: rg
  params: {
    location: location
    sqlServerName: sqlServerModule.outputs.serverName
    databaseName: sqlDatabaseName
    tags: baselineTags
  }
}

module apiAppModule './modules/appService.bicep' = {
  name: 'api-${nameSeed}'
  scope: rg
  params: {
    location: location
    appName: apiAppName
    planId: planModule.outputs.planId
    subnetId: apiSubnetId
    connectionStrings: [
      {
        name: 'SampleApiContext'
        connectionString: 'Server=tcp:${sqlServerModule.outputs.serverFullyQualifiedDomainName},1433;Initial Catalog=${databaseModule.outputs.databaseName};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication="Active Directory Default";'
        type: 'SQLAzure'
      }
    ]
    authClientId: keyVaultModule.outputs.apiAuthAppClientIdRef
    authClientSecret: keyVaultModule.outputs.apiAuthAppSecretRef
    isApi: true
    tags: baselineTags
  }
}

module webAppModule './modules/appService.bicep' = {
  name: 'web-${nameSeed}'
  scope: rg
  params: {
    location: location
    appName: webAppName
    planId: planModule.outputs.planId
    subnetId: webSubnetId
    appSettings: [
      {
        name: 'ApiUri'
        value: 'https://${apiAppModule.outputs.appUrl}'
      }
      {
        name: 'ApiAuthUri'
        value: 'api://${keyVaultModule.outputs.apiAuthAppClientIdRef}'
      }
    ]
    authClientId: keyVaultModule.outputs.webAuthAppClientIdRef
    authClientSecret: keyVaultModule.outputs.webAuthAppSecretRef
    isApi: false
    tags: baselineTags
  }
}

module sqlPrivateEndpoint './modules/privateEndpoint.bicep' = {
  name: 'pe-sql-${nameSeed}'
  scope: rg
  params: {
    location: location
    privateEndpointName: sqlPeName
    subnetId: peSubnetId
    resourceId: sqlServerModule.outputs.serverId
    groupId: 'sqlServer'
    dnsZoneId: sqlDnsZone.outputs.privateDnsId
    tags: baselineTags
  }
}

module apiAppPrivateEndpoint './modules/privateEndpoint.bicep' = {
  name: 'pe-api-${nameSeed}'
  scope: rg
  params: {
    location: location
    privateEndpointName: apiPeName
    subnetId: peSubnetId
    resourceId: apiAppModule.outputs.appId
    groupId: 'sites'
    dnsZoneId: appServiceDnsZone.outputs.privateDnsId
    tags: baselineTags
  }
}

@description('Resource ID of the deployed Resource Group.')
output resourceGroupId string = rg.id

@description('Name of the deployed Resource Group.')
output resourceGroupName string = rg.name

@description('Name of the Key Vault.')
output keyVaultName string = keyVaultModule.outputs.keyVaultName

@description('Vault URI of the Key Vault.')
output keyVaultUri string = keyVaultModule.outputs.vaultUri

@description('Key Vault secret references for downstream modules or templates.')
output keyVaultSecretReferences object = keyVaultModule.outputs.secretReferences

@description('Full HTTPS URL of the Web App.')
output webAppUrl string = 'https://${webAppModule.outputs.appUrl}'

@description('Full HTTPS URL of the API App.')
output apiAppUrl string = 'https://${apiAppModule.outputs.appUrl}'

@description('Fully Qualified Domain Name of the Azure SQL Server.')
output sqlServerFqdn string = sqlServerModule.outputs.serverFullyQualifiedDomainName

@description('Resource ID of the Spoke Virtual Network.')
output vnetId string = network.outputs.vnetId

@description('Deployment Stack name.')
output stackName string = stackName
