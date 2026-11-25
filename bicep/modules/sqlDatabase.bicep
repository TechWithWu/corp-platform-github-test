// modules/sqlDatabase.bicep
@description('Azure region for the SQL Database.')
param location string = resourceGroup().location

@description('Name of the parent SQL Logical Server.')
param sqlServerName string

@description('Name of the SQL Database.')
param databaseName string

@description('SKU name (e.g., S0, GP_S_Gen5_1, Basic).')
param skuName string = 'S0'

@description('SKU tier (e.g., Standard, GeneralPurpose, Basic).')
param skuTier string = 'Standard'

@description('Compute capacity / DTUs / vCores.')
param capacity int = 10

@description('Maximum database size in bytes (default 250 GB).')
param maxSizeBytes int = 268435456000

@description('Tags applied to the SQL Database.')
param tags object = {}

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' existing = {
  name: sqlServerName
}

resource database 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
    capacity: capacity
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: maxSizeBytes
  }
}

@description('Resource ID of the SQL Database.')
output databaseId string = database.id

@description('Name of the SQL Database.')
output databaseName string = database.name
