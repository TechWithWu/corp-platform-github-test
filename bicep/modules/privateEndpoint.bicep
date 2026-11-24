@description('Azure region for the Private Endpoint.')
param location string = resourceGroup().location

@description('Name of the Private Endpoint.')
param privateEndpointName string

@description('Subnet resource ID where the Private Endpoint NIC is placed.')
param subnetId string

@description('Target Azure resource ID to connect privately.')
param resourceId string

@description('Sub-resource group ID (e.g., sqlServer, sites, blob).')
param groupId string

@description('Private DNS Zone resource ID for DNS zone group registration.')
param dnsZoneId string

@description('Tags applied to the Private Endpoint.')
param tags object = {}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-${privateEndpointName}'
        properties: {
          privateLinkServiceId: resourceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }

  resource privateEndpointDnsEntry 'privateDnsZoneGroups' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'dns-config-${groupId}'
          properties: {
            privateDnsZoneId: dnsZoneId
          }
        }
      ]
    }
  }
}

@description('Resource ID of the Private Endpoint.')
output privateEndpointId string = privateEndpoint.id
