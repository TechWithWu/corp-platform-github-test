###############################################################################
# Locals - Connectivity Hub
###############################################################################

locals {
  # Location and naming
  location = var.location
  rg_name  = var.resource_group_name != "" ? var.resource_group_name : "rg-connectivity-hub-${var.environment}"

  # Centralized tagging
  common_tags = merge(
    {
      created_by  = "terraform"
      project     = "corp platform connectivity"
      owner       = "avm"
      environment = var.environment
      managed_by  = "terraform"
    },
    var.custom_tags
  )

  # Read and parse CSV configuration for spoke virtual networks
  spoke_vnets_csv = fileexists("${path.module}/config/spoke_vnets.csv") ? csvdecode(file("${path.module}/config/spoke_vnets.csv")) : []

  # Clean and filter spoke entries:
  # Excludes header comments (#), empty lines, and example placeholder rows
  spoke_peers = {
    for row in local.spoke_vnets_csv :
    trimspace(row.spoke_name) => {
      spoke_name                   = trimspace(row.spoke_name)
      remote_virtual_network_id    = trimspace(row.remote_virtual_network_id)
      hub_vnet_key                 = try(trimspace(lookup(row, "hub_vnet_key", "")), "")
      allow_forwarded_traffic      = try(tobool(row.allow_forwarded_traffic), true)
      allow_gateway_transit        = try(tobool(row.allow_gateway_transit), false)
      use_remote_gateways          = try(tobool(row.use_remote_gateways), false)
      allow_virtual_network_access = try(tobool(row.allow_virtual_network_access), true)
    }
    if trimspace(lookup(row, "remote_virtual_network_id", "")) != ""
    && !startswith(trimspace(lookup(row, "spoke_name", "")), "#")
    && !can(regex("(?i)example|placeholder|<.*>", lookup(row, "remote_virtual_network_id", "")))
  }
}