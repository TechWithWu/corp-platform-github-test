using './main.bicep'

// ==========================================
// Production Environment Parameters
// ==========================================

param workload = 'finance'
param environment = 'prod'
param location = 'centralus'
param instanceIndex = 1

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

param appServicePlanSku = 'B1'
param sqlDatabaseName = 'sqldb-finance-prod'

// Identity & Governance
param sqlAdminObjectId = '00000000-0000-0000-0000-000000000001'
param sqlAdminLogin = 'EntraAdmin-Finance-Prod'
param webAuthAppClientId = '11111111-1111-1111-1111-111111111111'
param apiAuthAppClientId = '22222222-2222-2222-2222-222222222222'

param extraTags = {
  Environment: 'Production'
  DataClassification: 'Confidential'
  BusinessCriticality: 'MissionCritical'
  Compliance: 'SOC2-ISO27001'
}
