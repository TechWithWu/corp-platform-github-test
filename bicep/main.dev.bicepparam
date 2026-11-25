using './main.bicep'

// ==========================================
// Development Environment Parameters
// ==========================================

// Workload & Environment Identity
param workload = 'finance'
param environment = 'dev'
param instanceIndex = 1
param stackName = 'stack-finance-dev'

// Region & Location Parameterization
param location = 'centralus'
param keyVaultLocation = 'centralus'
param databaseLocation = 'centralus'
param appServiceLocation = 'centralus'

// Key Vault Tier Configurations
param keyVaultSkuName = 'standard'
param keyVaultSoftDeleteRetentionInDays = 7
param keyVaultEnablePurgeProtection = false
param webAuthAppClientId = '33333333-3333-3333-3333-333333333333'
param apiAuthAppClientId = '44444444-4444-4444-4444-444444444444'

// Database Tier Configurations
param sqlDatabaseName = 'sqldb-finance-dev'
param sqlDatabaseSkuName = 'Basic'
param sqlDatabaseSkuTier = 'Basic'
param sqlDatabaseCapacity = 5
param sqlDatabaseMaxSizeBytes = 34359738368 // 32 GB
param sqlAdminObjectId = '00000000-0000-0000-0000-000000000002'
param sqlAdminLogin = 'EntraAdmin-Finance-Dev'
param sqlAdminPrincipalType = 'Group'

// App Service Tier Configurations
param appServicePlanSku = 'B1'
param appServicePlanTier = 'Basic'
param appServicePlanCapacity = 1
param appServiceLinuxFxVersion = 'DOTNETCORE|8.0'

// Networking & Hub Configurations
param vnetAddressPrefix = '10.2.0.0/16'
param subnets = [
  {
    name: 'snet-web'
    addressPrefix: '10.2.1.0/24'
    delegation: 'Microsoft.Web/serverFarms'
  }
  {
    name: 'snet-api'
    addressPrefix: '10.2.2.0/24'
    delegation: 'Microsoft.Web/serverFarms'
  }
  {
    name: 'snet-pe'
    addressPrefix: '10.2.3.0/24'
  }
]

param hubSubscriptionId = '7f493ff6-603b-4254-a6bf-e9acfc665866'
param hubResourceGroupName = 'rg-connectivity-hub-dev'
param hubVnetName = 'vnet-platform-connectivity-dev'

// Governance & Baseline Tags
param extraTags = {
  Environment: 'Development'
  DataClassification: 'Internal'
  BusinessCriticality: 'Low'
  AutoShutdown: 'True'
}
