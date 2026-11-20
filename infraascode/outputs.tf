###############################################################################
# Outputs - Connectivity Hub
###############################################################################

output "resource_group_id" {
  description = "The Resource ID of the Connectivity Hub resource group."
  value       = module.resource_group.resource.id
}

output "resource_group_name" {
  description = "The name of the Connectivity Hub resource group."
  value       = module.resource_group.resource.name
}

output "resource_group_location" {
  description = "The Azure region of the Connectivity Hub."
  value       = module.resource_group.resource.location
}

output "hub_vnet_id" {
  description = "The Azure Resource ID of the centralized Hub Virtual Network."
  value       = module.connectivity_hub_and_spoke.virtual_network_resource_ids["primary"]
}

output "hub_vnet_name" {
  description = "The name of the centralized Hub Virtual Network."
  value       = local.hub_name
}

output "peered_spoke_vnets" {
  description = "List of spoke virtual network names currently configured for Hub-side peering."
  value       = module.spoke_peering.peered_spoke_names
}
