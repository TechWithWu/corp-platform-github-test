@description('Azure region for the App Service Plan.')
param location string = resourceGroup().location

@description('Name of the App Service Plan.')
@minLength(1)
@maxLength(60)
param planName string

@description('SKU name for the Linux App Service Plan.')
param skuName string = 'B1'

@description('SKU tier for the Linux App Service Plan.')
param skuTier string = 'Basic'

@description('Number of worker instances.')
@minValue(1)
param capacity int = 1

@description('Tags applied to the resource.')
param tags object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
    capacity: capacity
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

@description('Resource ID of the App Service Plan.')
output planId string = appServicePlan.id

@description('Name of the App Service Plan.')
output planName string = appServicePlan.name