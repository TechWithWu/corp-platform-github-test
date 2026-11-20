###############################################################################
# Hub-to-Spoke Virtual Network Peering (Hub-Side Only)
# Uses native azurerm_virtual_network_peering to establish connection from Hub
# to remote Spoke VNets without requiring cross-subscription write permissions.
# Spoke subscriptions independently establish their own Spoke-to-Hub peering.
###############################################################################

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.spoke_peers

  name                         = "peer-hub-to-${each.key}"
  resource_group_name          = var.hub_resource_group_name
  virtual_network_name         = var.hub_virtual_network_name
  remote_virtual_network_id    = each.value.remote_virtual_network_id
  allow_virtual_network_access = each.value.allow_virtual_network_access
  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.allow_gateway_transit
  use_remote_gateways          = each.value.use_remote_gateways
}
