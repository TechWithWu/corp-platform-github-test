###############################################################################
# Hub Virtual Networks Configuration
#
# This file centralizes the definition of all Hub Virtual Networks and their
# subnets. If you need to add a new Hub VNet (e.g., multi-region expansion,
# secondary transit hub), simply add a new key/block to the `hub_vnets` map.
###############################################################################

locals {
  hub_vnets = {
    # Primary Hub Virtual Network
    "primary" = {
      name          = var.hub_vnet_name
      location      = local.location
      address_space = ["10.0.0.0/16"]

      # Distinct subnets configuration for this Hub VNet
      subnets = {
        default = {
          name             = "snet-default"
          address_prefixes = ["10.0.1.0/24"]
        }
        shared = {
          name             = "snet-shared-services"
          address_prefixes = ["10.0.2.0/24"]
        }
      }
    }

    # Example: Easily extendable for additional Hub VNets (e.g. secondary region):
    # "secondary" = {
    #   name          = "vnet-hub-centralus-001"
    #   location      = "centralus"
    #   address_space = ["10.10.0.0/16"]
    #   subnets = {
    #     default = {
    #       name             = "snet-default"
    #       address_prefixes = ["10.10.1.0/24"]
    #     }
    #     gateway = {
    #       name             = "GatewaySubnet"
    #       address_prefixes = ["10.10.254.0/24"]
    #     }
    #   }
    # }
  }
}
