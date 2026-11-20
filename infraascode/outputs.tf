###############################################################################
# Outputs - Connectivity Hub
###############################################################################

output "resource_group_id" {
  description = "The Resource ID of the Connectivity Hub resource group."
  value       = module.resource_group.id
}

output "resource_group_name" {
  description = "The name of the Connectivity Hub resource group."
  value       = module.resource_group.name
}

output "resource_group_location" {
  description = "The Azure region of the Connectivity Hub."
  value       = module.resource_group.location
}

output "hub_vnet_id" {
  description = "The Azure Resource ID of the centralized Hub Virtual Network."
  value       = module.connectivity_hub_and_spoke.virtual_network_resource_ids["primary"]
}

output "firewall_private_ip" {
  description = "The private IP address of Azure Firewall (used as the next-hop IP for route tables in spoke subscriptions)."
  value       = module.connectivity_hub_and_spoke.firewall_private_ip_addresses["primary"]
}

output "firewall_public_ips" {
  description = "The public IP addresses assigned to Azure Firewall for outbound SNAT and inbound DNAT."
  value       = module.connectivity_hub_and_spoke.firewall_public_ip_addresses["primary"]
}

output "hub_route_table_id" {
  description = "The Resource ID of the Hub user subnets route table pointing to the Firewall."
  value       = module.connectivity_hub_and_spoke.route_table_resource_ids_by_hub_key["primary"].user_subnets
}

output "peered_spoke_vnets" {
  description = "List of spoke virtual network names currently peered to the Hub."
  value       = module.spoke_peering.peered_spoke_names
}
