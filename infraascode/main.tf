###############################################################################
# Centralized Connectivity Hub
# Manages the primary Hub VNet and Hub-Side Spoke Peerings
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
# HUB – AVM ALZ Connectivity Pattern Module
# Provisions the centralized Hub Virtual Network (Firewall & VPN disabled)
###############################################################################
module "hub_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.17"

  name           = "vnet-hub-centralus-001"
  location       = "centralus"
  address_space  = ["10.0.0.0/16"]

  # pass the RG resource ID (what you already have)
  parent_id = module.resource_group.resource_id

  subnets = {
    default = {
      name             = "snet-default"
      address_prefixes = ["10.0.1.0/24"]
    }
  }

  enable_telemetry = false
  tags             = local.common_tags
}

###############################################################################
# Spoke Virtual Network Peering Submodule
# Uses native azurerm_virtual_network_peering to establish Hub-side peering
# without requiring cross-subscription write permissions on spoke subscriptions
###############################################################################
# module "spoke_peering" {
#   source = "./modules/spoke_peering"

#   hub_virtual_network_name = local.hub_name
#   hub_resource_group_name  = module.resource_group.resource.name
#   spoke_peers              = local.spoke_peers
# }