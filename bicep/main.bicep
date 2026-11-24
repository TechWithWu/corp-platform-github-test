targetScope = 'subscription'

@description('Workload identifier.')
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

@description('Instance index for naming.')
@minValue(1)
param instanceIndex int = 1

@description('Spoke VNet CIDR.')
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

@description('Hub subscription ID.')
param hubSubscriptionId string = '7f493ff6-603b-4254-a6bf-e9acfc665866'

@description('Hub resource group name.')
param hubResourceGroupName string = 'rg-connectivity-hub-prod'

@description('Hub VNet name.')
param hubVnetName string = 'vnet-platform-connectivity-prod'

@description('App Service Plan SKU name.')
param appServicePlanSku string = 'B1'

@description('SQL Database name.')
param sqlDatabaseName string = 'sqldb-finance-prod'

@description('Entra ID Admin Object ID for SQL Server.')
param sqlAdminObjectId string

@description('Entra ID Admin Login/Name for SQL Server.')
param sqlAdminLogin string

@description('Web App Entra ID Client ID.')
param webAuthAppClientId string

@description('Web App Entra ID Client Secret or Key Vault URI reference.')
@secure()
param webAuthAppSecret string = ''

@description('API App Entra ID Client ID.')
param apiAuthAppClientId string

@description('API App Entra ID Client Secret or Key Vault URI reference.')
@secure()
param apiAuthAppSecret string = ''

@description('Additional tags merged with baseline tags.')
param extraTags object = {}

var paddedIndex = padLeft(string(instanceIndex), 2, '0')
var nameSeed = '${workload}-${environment}-${paddedIndex}'
var rgName = 'rg-${nameSeed}'
var planName = 'asp-${nameSeed}'
var webAppName = 'app-web-${nameSeed}'
var apiAppName = 'app-api-${nameSeed}'
var sqlServerName = 'sql-${nameSeed}'
var sqlPeName = 'pe-sql-${nameSeed}'
var apiPeName = 'pe-api-${nameSeed}'

var hubVnetId = '/subscriptions/${hubSubscriptionId}/resourceGroups/${hubResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${hubVnetName}'

var baselineTags = union(extraTags, {
  workload: workload
  environment: environment
  managedBy: 'bicep-deployment-stack'
  costCenter: toLower('${workload}-${environment}')
})

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: baselineTags
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
    dnsZoneName: 'privatelink${environment().suffixes.sqlServerHostname}'
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
    authClientId: apiAuthAppClientId
    authClientSecret: apiAuthAppSecret
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
        value: 'api://${apiAuthAppClientId}'
      }
    ]
    authClientId: webAuthAppClientId
    authClientSecret: webAuthAppSecret
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

output resourceGroupName string = rg.name
output webAppUrl string = 'https://${webAppModule.outputs.appUrl}'
output apiAppUrl string = 'https://${apiAppModule.outputs.appUrl}'
output stackName string = stackName