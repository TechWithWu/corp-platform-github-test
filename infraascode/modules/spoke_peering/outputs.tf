###############################################################################
# Spoke Peering Outputs
###############################################################################

output "peerings" {
  description = "Map of Hub-to-Spoke virtual network peering resources."
  value       = azurerm_virtual_network_peering.hub_to_spoke
}

output "peered_spoke_names" {
  description = "List of spoke network names configured for Hub-side peering."
  value       = keys(var.spoke_peers)
}
