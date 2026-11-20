###############################################################################
# Centralized Connectivity Hub
# Manages the primary Hub VNet, Azure Firewall (Basic SKU), and Spoke Peerings
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
# Dedicated 2nd Data-Plane Public IP for Azure Firewall
###############################################################################
resource "azurerm_public_ip" "fw_data_2" {
  name                = "pip-fw-data-2-${random_string.suffix.result}"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

###############################################################################
# HUB – AVM ALZ Connectivity Pattern Module (Firewall Basic SKU)
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
            name                      = "snet-hub-shared"
            address_prefixes          = [local.hub_mgmt_cidr]
            route_table_key_reference = "hub_user_subnets"
          }
        }

        ########## Azure Firewall (Basic SKU) ##########
        # Basic SKU requires:
        # - AzureFirewallSubnet (/26)
        # - AzureFirewallManagementSubnet (/26)
        firewall = {
          sku_name                         = "AZFW_VNet"
          sku_tier                         = "Basic"
          subnet_address_prefix            = local.fw_subnet_cidr
          management_subnet_address_prefix = local.fw_mgmt_cidr

          ip_configurations = {
            primary = {
              is_default                 = true
              public_ip_creation_enabled = true
              public_ip_name             = "pip-fw-data-1-${random_string.suffix.result}"
              public_ip_configuration = {
                sku               = "Standard"
                allocation_method = "Static"
                zones             = []
              }
            }
            secondary = {
              is_default                 = false
              public_ip_creation_enabled = false
              public_ip_id               = azurerm_public_ip.fw_data_2.id
            }
          }

          management_ip_configuration = {
            public_ip_creation_enabled = true
            public_ip_name             = "pip-fw-mgmt-${random_string.suffix.result}"
            public_ip_configuration = {
              sku               = "Standard"
              allocation_method = "Static"
              zones             = []
            }
          }
        }

        ########## Firewall Policy & Baseline Rules ##########
        firewall_policy = {
          sku = "Basic"
          base_policy = {
            rule_collection_groups = {
              default = {
                priority = 100

                # 1. Outbound Network Rules
                network_rule_collections = {
                  outbound_internet = {
                    priority = 300
                    action   = "Allow"
                    rules = {
                      workloads_to_internet = {
                        protocols             = ["TCP", "UDP"]
                        source_addresses      = [local.hub_cidr, "10.0.0.0/8"]
                        destination_addresses = ["*"]
                        destination_ports     = ["80", "443", "53", "123"]
                      }
                    }
                  }
                }

                # 2. Application Rules (Core Azure / Microsoft services)
                application_rule_collections = {
                  allow_fqdn = {
                    priority = 400
                    action   = "Allow"
                    rules = {
                      ms_and_azure = {
                        source_addresses = [local.hub_cidr, "10.0.0.0/8"]
                        protocols        = [{ type = "Https", port = 443 }]
                        fqdn_tags        = ["WindowsUpdate", "AzureActiveDirectory"]
                        target_fqdns     = ["*.azure.com", "*.microsoft.com"]
                      }
                    }
                  }
                }
              }
            }
          }
        }

        ########## Routing: Route Table pointing default traffic to Firewall ##########
        route_table_name_user_subnets = "rt-hub-user-subnets-${random_string.suffix.result}"
        route_table_entries_user_subnets = {
          default_via_firewall = {
            address_prefix         = "0.0.0.0/0"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = "use_firewall_private_ip"
          }
        }

        ########## Enabled / Disabled Hub Components ##########
        # VPN Gateway removed; only Firewall enabled
        enabled_resources = {
          firewall                = true
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
# Dynamically manages peerings for spokes listed in config/spoke_vnets.csv
###############################################################################
module "spoke_peering" {
  source = "./modules/spoke_peering"

  hub_virtual_network_id = module.connectivity_hub_and_spoke.virtual_network_resource_ids["primary"]
  spoke_peers            = local.spoke_peers
}