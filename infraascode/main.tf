###############################################################################
# Centralized Connectivity Hub
# Manages Hub VNets (defined in local.config.tf) and Spoke Peering connections
###############################################################################

###############################################################################
# Suffix Generator
###############################################################################
resource "random_string" "suffix" {
  length  = 4
  numeric = true
  special = false
  upper   = false
}

###############################################################################
# Resource Group (AVM Resource Module)
###############################################################################
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.5.0"

  name             = local.rg_name
  location         = local.location
  enable_telemetry = var.enable_telemetry
  tags             = local.common_tags
}

###############################################################################
# HUB – AVM Virtual Network Module (Extendable)
# Provisions all Hub Virtual Networks and custom subnets from local.config.tf
###############################################################################
module "hub_vnet" {
  for_each = local.hub_vnets

  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.17"

  name          = each.value.name
  location      = try(each.value.location, local.location)
  address_space = each.value.address_space

  # Pass the RG resource ID
  parent_id = module.resource_group.resource_id

  subnets = each.value.subnets

  enable_telemetry = var.enable_telemetry
  tags             = local.common_tags
}

###############################################################################
# Spoke Virtual Network Peering Submodule
# Uses native azurerm_virtual_network_peering to establish Hub-side peering
# without requiring cross-subscription write permissions on spoke subscriptions
###############################################################################
module "spoke_peering" {
  source = "./modules/spoke_peering"

  hub_virtual_networks = {
    for k, v in local.hub_vnets : k => {
      name                = v.name
      resource_group_name = local.rg_name
      id                  = module.hub_vnet[k].resource_id
    }
  }

  spoke_peers = local.spoke_peers
}