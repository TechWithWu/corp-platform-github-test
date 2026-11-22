###############################################################################
# Hub-to-Spoke Virtual Network Peering (Hub-Side Only)
# Uses native azurerm_virtual_network_peering to establish connection from Hub
# to remote Spoke VNets without requiring cross-subscription write permissions.
# Spoke subscriptions independently establish their own Spoke-to-Hub peering.
###############################################################################

locals {
  # Consolidate available hub VNets from either map or single variables
  available_hubs = length(keys(var.hub_virtual_networks)) > 0 ? var.hub_virtual_networks : (
    var.hub_virtual_network_name != "" ? {
      "default" = {
        name                = var.hub_virtual_network_name
        resource_group_name = var.hub_resource_group_name
        id                  = ""
      }
    } : {}
  )

  default_hub_key = length(keys(local.available_hubs)) > 0 ? keys(local.available_hubs)[0] : ""

  # Resolve target hub for each spoke (defaults to first/primary hub if unspecified)
  resolved_spoke_peers = {
    for k, v in var.spoke_peers : k => merge(v, {
      resolved_hub_key = v.hub_vnet_key != "" && contains(keys(local.available_hubs), v.hub_vnet_key) ? v.hub_vnet_key : local.default_hub_key
    })
    if length(keys(local.available_hubs)) > 0
  }
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = local.resolved_spoke_peers

  name                         = "peer-${each.value.resolved_hub_key}-to-${each.key}"
  resource_group_name          = local.available_hubs[each.value.resolved_hub_key].resource_group_name
  virtual_network_name         = local.available_hubs[each.value.resolved_hub_key].name
  remote_virtual_network_id    = each.value.remote_virtual_network_id
  allow_virtual_network_access = each.value.allow_virtual_network_access
  allow_forwarded_traffic      = each.value.allow_forwarded_traffic
  allow_gateway_transit        = each.value.allow_gateway_transit
  use_remote_gateways          = each.value.use_remote_gateways
}
