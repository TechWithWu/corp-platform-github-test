@description('Azure region for network resources.')
param location string = resourceGroup().location

@description('Naming seed for resources (e.g., finance-prod-01).')
param nameSeed string

@description('Address space CIDR for the spoke Virtual Network.')
param vnetAddressPrefix string

@description('Subnet definitions ({ name, addressPrefix, delegation? }).')
param subnets array = []

@description('Resource ID of the Hub Virtual Network.')
param hubVnetId string

@description('Name of the Hub Virtual Network.')
param hubVnetName string

@description('Tags applied to network resources.')
param tags object = {}

module network './network.bicep' = {
  name: 'network-${nameSeed}'
  params: {
    location: location
    nameSeed: nameSeed
    vnetAddressPrefix: vnetAddressPrefix
    subnets: subnets
    hubVnetId: hubVnetId
    hubVnetName: hubVnetName
    tags: tags
  }
}

@description('Resource ID of the spoke Virtual Network.')
output vnetId string = network.outputs.vnetId

@description('Name of the spoke Virtual Network.')
output vnetName string = network.outputs.vnetName

@description('Subnets array of the spoke Virtual Network.')
output subnets array = network.outputs.subnets

@description('Subnet ID for Web App Service integration.')
output webSubnetId string = filter(network.outputs.subnets, s => s.name == 'snet-web')[0].id

@description('Subnet ID for API App Service integration.')
output apiSubnetId string = filter(network.outputs.subnets, s => s.name == 'snet-api')[0].id

@description('Subnet ID for Private Endpoints.')
output peSubnetId string = filter(network.outputs.subnets, s => s.name == 'snet-pe')[0].id
