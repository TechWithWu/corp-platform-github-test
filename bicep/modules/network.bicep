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

@description('Enable gateway transit on spoke-to-hub peering.')
param allowGatewayTransit bool = false

@description('Use remote gateways from hub on spoke peering.')
param useRemoteGateways bool = false

@description('Tags applied to network resources.')
param tags object = {}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-${nameSeed}'
  location: location
  tags: tags
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-${nameSeed}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    enableDdosProtection: false
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: {
          id: nsg.id
        }
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
        delegations: contains(subnet, 'delegation') && !empty(subnet.delegation) ? [
          {
            name: 'delegation-${subnet.name}'
            properties: {
              serviceName: subnet.delegation
            }
          }
        ] : []
      }
    }]
  }
}

resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: vnet
  name: 'peer-${vnet.name}-to-${hubVnetName}'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
  }
}

@description('Resource ID of the spoke Virtual Network.')
output vnetId string = vnet.id

@description('Name of the spoke Virtual Network.')
output vnetName string = vnet.name

@description('Subnets created in the spoke Virtual Network.')
output subnets array = vnet.properties.subnets