###############################################################################
# Hub to Spoke Virtual Network Peering (AVM Module)
###############################################################################

module "peering" {
  for_each = var.spoke_peers

  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/peering"
  version = "~> 0.9"

  virtual_network = {
    resource_id = var.hub_virtual_network_id
  }

  remote_virtual_network = {
    resource_id = each.value.remote_virtual_network_id
  }

  name                         = "peer-hub-to-${each.key}"
  remote_peering_name          = "peer-${each.key}-to-hub"
  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.allow_gateway_transit
  use_remote_gateways          = each.value.use_remote_gateways
  allow_virtual_network_access = each.value.allow_virtual_network_access
  peer_complete_vnets          = true
}
