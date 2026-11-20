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
  version = "0.2.0"

  name             = local.rg_name
  location         = local.location
  enable_telemetry = var.enable_telemetry
  tags             = local.common_tags
}

###############################################################################
# HUB – AVM ALZ Connectivity Pattern Module
# Provisions the centralized Hub Virtual Network (Firewall & VPN disabled)
###############################################################################
module "connectivity_hub_and_spoke" {
  source  = "Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm"
  version = "~> 0.18.3"

  enable_telemetry = var.enable_telemetry

  hub_and_spoke_networks_settings = {
    enabled_resources = {
      ddos_protection_plan = false
    }
  }

  hub_virtual_networks = {
    primary = {
      ########## Hub VNet ##########
      hub_virtual_network = {
        name                            = local.hub_name
        location                        = module.resource_group.location
        resource_group_name             = module.resource_group.name
        resource_group_creation_enabled = false
        address_space                   = [local.hub_cidr]

        subnets = {
          hub_shared = {
            name             = "snet-hub-shared"
            address_prefixes = [local.hub_mgmt_cidr]
          }
        }

        ########## Enabled / Disabled Hub Components ##########
        # Firewall and VPN Gateway removed
        enabled_resources = {
          firewall                = false
          nat_gateway             = false
          bastion                 = false
          virtual_network_gateway = false
          private_dns_zones       = false
          private_dns_resolver    = false
          ddos_protection_plan    = false
        }
      }

      bastion              = { enabled = false }
      private_dns_zones    = null
      private_dns_resolver = null
    }
  }

  tags = local.common_tags
}

###############################################################################
# Spoke Virtual Network Peering Submodule
# Uses native azurerm_virtual_network_peering to establish Hub-side peering
# without requiring cross-subscription write permissions on spoke subscriptions
###############################################################################
module "spoke_peering" {
  source = "./modules/spoke_peering"

  hub_virtual_network_name = local.hub_name
  hub_resource_group_name  = module.resource_group.name
  spoke_peers              = local.spoke_peers
}