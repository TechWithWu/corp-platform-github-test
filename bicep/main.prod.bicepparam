using './main.bicep'

// ==========================================
// Production Environment Parameters
// ==========================================

param workload = 'finance'
param environment = 'prod'
param location = 'westus2'
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
param sqlAdminObjectId = 'cd016e03-5f34-404d-bb50-c139970285c3' //guokaswu_gmail.com
param sqlAdminLogin = 'EntraAdmin-Finance-Prod'

param extraTags = {
  Environment: 'Production'
  DataClassification: 'Confidential'
  BusinessCriticality: 'MissionCritical'
  Compliance: 'SOC2-ISO27001'
}
