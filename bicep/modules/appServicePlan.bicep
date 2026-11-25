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

module appServicePlanAvm 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'avm-asp-${planName}'
  params: {
    name: planName
    location: location
    tags: tags
    sku: {
      name: skuName
      tier: skuTier
      capacity: capacity
    }
    kind: 'linux'
    reserved: true
  }
}

@description('Resource ID of the App Service Plan.')
output planId string = appServicePlanAvm.outputs.resourceId

@description('Name of the App Service Plan.')
output planName string = appServicePlanAvm.outputs.name