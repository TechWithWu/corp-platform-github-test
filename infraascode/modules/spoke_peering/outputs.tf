###############################################################################
# Spoke Peering Outputs
###############################################################################

output "peerings" {
  description = "Map of all virtual network peering resources created by the module."
  value       = module.peering
}

output "peered_spoke_names" {
  description = "List of spoke network names configured for peering."
  value       = keys(var.spoke_peers)
}
