@description('Private DNS Zone name (e.g., privatelink.database.windows.net).')
param dnsZoneName string

@description('Virtual Network resource ID to link to the Private DNS Zone.')
param vnetId string

@description('Enable auto-registration in the Private DNS Zone.')
param registrationEnabled bool = false

@description('Tags applied to the Private DNS Zone.')
param tags object = {}

var vnetName = last(split(vnetId, '/'))

resource privateDns 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: dnsZoneName
  location: 'global'
  tags: tags

  resource vnetLink 'virtualNetworkLinks' = {
    name: 'link-${vnetName}'
    location: 'global'
    properties: {
      registrationEnabled: registrationEnabled
      virtualNetwork: {
        id: vnetId
      }
    }
  }
}

@description('Resource ID of the Private DNS Zone.')
output privateDnsId string = privateDns.id