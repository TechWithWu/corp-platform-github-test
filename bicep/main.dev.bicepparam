using './main.bicep'

// ==========================================
// Development Environment Parameters
// ==========================================

param workload = 'finance'
param environment = 'dev'
param location = 'centralus'
param instanceIndex = 1

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

param appServicePlanSku = 'B1'
param sqlDatabaseName = 'sqldb-finance-dev'

// Identity & Governance
param sqlAdminObjectId = '00000000-0000-0000-0000-000000000002'
param sqlAdminLogin = 'EntraAdmin-Finance-Dev'
param webAuthAppClientId = '33333333-3333-3333-3333-333333333333'
param apiAuthAppClientId = '44444444-4444-4444-4444-444444444444'

param extraTags = {
  Environment: 'Development'
  DataClassification: 'Internal'
  BusinessCriticality: 'Low'
  AutoShutdown: 'True'
}
