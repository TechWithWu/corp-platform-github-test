using './main.bicep'

// ==========================================
// Production Environment Parameters
// ==========================================

// Workload & Environment Identity
param workload = 'finance'
param environment = 'prod'
param instanceIndex = 1
param stackName = 'stack-finance-prod'

// Region & Location Parameterization
param location = 'westus2'
param keyVaultLocation = 'westus2'
param databaseLocation = 'westus2'
param appServiceLocation = 'westus2'

// Key Vault Tier Configurations
param keyVaultSkuName = 'standard'
param keyVaultSoftDeleteRetentionInDays = 90
param keyVaultEnablePurgeProtection = true

// Database Tier Configurations
param sqlDatabaseName = 'sqldb-finance-prod'
param sqlDatabaseSkuName = 'S0'
param sqlDatabaseSkuTier = 'Standard'
param sqlDatabaseCapacity = 10
param sqlDatabaseMaxSizeBytes = 268435456000 // 250 GB
param sqlAdminObjectId = 'cd016e03-5f34-404d-bb50-c139970285c3' // guokaswu_gmail.com
param sqlAdminLogin = 'EntraAdmin-Finance-Prod'
param sqlAdminPrincipalType = 'Group'

// App Service Tier Configurations
param appServicePlanSku = 'B1'
param appServicePlanTier = 'Basic'
param appServicePlanCapacity = 1
param appServiceLinuxFxVersion = 'DOTNETCORE|8.0'

// Networking & Hub Configurations
param vnetAddressPrefix = '10.1.0.0/16'
param subnets = [
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

param hubSubscriptionId = '7f493ff6-603b-4254-a6bf-e9acfc665866'
param hubResourceGroupName = 'rg-connectivity-hub-prod'
param hubVnetName = 'vnet-platform-connectivity-prod'

// Governance & Baseline Tags
param extraTags = {
  Environment: 'Production'
  DataClassification: 'Confidential'
  BusinessCriticality: 'MissionCritical'
  Compliance: 'SOC2-ISO27001'
}
