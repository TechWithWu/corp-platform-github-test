@description('Azure region for the SQL resources.')
param location string = resourceGroup().location

@description('Azure region for the Private Endpoint (must match the VNet/subnet region).')
param privateEndpointLocation string = location

@description('Naming seed for resources (e.g., finance-prod-01).')
param nameSeed string

@description('Name of the Azure SQL Logical Server.')
param sqlServerName string

@description('Name of the SQL Database.')
param sqlDatabaseName string

@description('Entra ID Admin Object ID for SQL Server.')
param sqlAdminObjectId string

@description('Entra ID Admin Login/Name for SQL Server.')
param sqlAdminLogin string

@description('Principal type for Entra ID admin (Application, User, or Group).')
@allowed([
  'Application'
  'User'
  'Group'
])
param sqlAdminPrincipalType string = 'Group'

@description('SKU name for the SQL Database (e.g., Basic, S0, GP_S_Gen5_1).')
param skuName string = 'S0'

@description('SKU tier for the SQL Database (e.g., Basic, Standard, GeneralPurpose).')
param skuTier string = 'Standard'

@description('Compute capacity / DTUs / vCores.')
param capacity int = 10

@description('Maximum database size in bytes.')
param maxSizeBytes int = 268435456000

@description('Disable public network access.')
param disablePublicNetworkAccess bool = true

@description('Subnet resource ID where the Private Endpoint NIC is attached.')
param peSubnetId string

@description('Virtual Network resource ID for Private DNS Zone link.')
param vnetId string

@description('Tags applied to database tier resources.')
param tags object = {}

var sqlPeName = 'pe-sql-${nameSeed}'

module sqlServerModule './sqlServer.bicep' = {
  name: 'sqlsrv-${nameSeed}'
  params: {
    location: location
    sqlServerName: sqlServerName
    sqlAdminObjectId: sqlAdminObjectId
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPrincipalType: sqlAdminPrincipalType
    disablePublicNetworkAccess: disablePublicNetworkAccess
    tags: tags
  }
}

module databaseModule './sqlDatabase.bicep' = {
  name: 'sqldb-${nameSeed}'
  params: {
    location: location
    sqlServerName: sqlServerModule.outputs.serverName
    databaseName: sqlDatabaseName
    skuName: skuName
    skuTier: skuTier
    capacity: capacity
    maxSizeBytes: maxSizeBytes
    tags: tags
  }
}

module sqlDnsZone './privateDns.bicep' = {
  name: 'dns-sql-${nameSeed}'
  params: {
    dnsZoneName: 'privatelink${az.environment().suffixes.sqlServerHostname}'
    vnetId: vnetId
    tags: tags
  }
}

module sqlPrivateEndpoint './privateEndpoint.bicep' = {
  name: 'pe-sql-${nameSeed}'
  params: {
    location: privateEndpointLocation
    privateEndpointName: sqlPeName
    subnetId: peSubnetId
    resourceId: sqlServerModule.outputs.serverId
    groupId: 'sqlServer'
    dnsZoneId: sqlDnsZone.outputs.privateDnsId
    tags: tags
  }
}

@description('FQDN of the SQL Logical Server.')
output serverFullyQualifiedDomainName string = sqlServerModule.outputs.serverFullyQualifiedDomainName

@description('Resource ID of the SQL Logical Server.')
output serverId string = sqlServerModule.outputs.serverId

@description('Name of the SQL Logical Server.')
output serverName string = sqlServerModule.outputs.serverName

@description('Name of the SQL Database.')
output databaseName string = databaseModule.outputs.databaseName

@description('Resource ID of the SQL Database.')
output databaseId string = databaseModule.outputs.databaseId

@description('Private Endpoint Resource ID for SQL Server.')
output privateEndpointId string = sqlPrivateEndpoint.outputs.privateEndpointId

@description('Standard Entra ID Default AD connection string for applications.')
output connectionString string = 'Server=tcp:${sqlServerModule.outputs.serverFullyQualifiedDomainName},1433;Initial Catalog=${databaseModule.outputs.databaseName};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication="Active Directory Default";'
