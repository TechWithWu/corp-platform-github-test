###############################################################################
# Terraform & providers
# ALZ AVM pattern modules require azurerm ~> 4.0 (v5 not yet supported)
###############################################################################
terraform {
  required_version = "~> 1.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "azurerm" {
  features {}
}

###############################################################################
# Suffix + locals
###############################################################################
resource "random_string" "suffix" {
  length  = 4
  numeric = true
  special = false
  upper   = false
}

locals {
  location = "swedencentral"

  common_tags = {
    created_by  = "terraform"
    project     = "Azure Landing Zones"
    owner       = "avm"
    environment = "demo"
  }

  hub_name     = "vnet-platform-connectivity"
  hub_cidr     = "10.0.0.0/16"
  finance_cidr = "10.1.0.0/16"
  eshop_cidr   = "10.2.0.0/16"

  # Firewall subnet MUST be /26 and named AzureFirewallSubnet.
  # Basic SKU additionally requires AzureFirewallManagementSubnet (/26).
  fw_subnet_cidr  = "10.0.100.0/26"
  fw_mgmt_cidr    = "10.0.101.0/26"
  gw_subnet_cidr  = "10.0.2.0/27"
  hub_mgmt_cidr   = "10.0.1.0/24" # hub shared-services subnet
  vpn_client_cidr = "172.16.0.0/24" # P2S VPN client address pool

  spoke_finance_subnet_cidr = "10.1.1.0/24"
  spoke_eshop_subnet_cidr   = "10.2.1.0/24"

  finance_web_ip = "10.1.1.4"
  eshop_web_ip   = "10.2.1.4"

  rg_name = "rg-hub-spoke-${random_string.suffix.result}"
}

###############################################################################
# Resource group (AVM resource module)
###############################################################################
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.0"

  name             = local.rg_name
  location         = local.location
  enable_telemetry = false
  tags             = local.common_tags
}

###############################################################################
# Dedicated 2nd Data-Plane Public IP for Firewall (referenced directly in DNAT)
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
# HUB – AVM ALZ connectivity pattern module (Firewall + P2S VPN)
###############################################################################
module "connectivity_hub_and_spoke" {
  source  = "Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm"
  version = "~> 0.18.3"

  enable_telemetry = false

  hub_and_spoke_networks_settings = {
    enabled_resources = {
      ddos_protection_plan = false
    }
  }

  hub_virtual_networks = {
    primary = {
      ########## Hub VNet ##########
      hub_virtual_network = {
        name                          = local.hub_name
        location                      = module.resource_group.location
        resource_group_name           = module.resource_group.name
        resource_group_creation_enabled = false
        address_space                 = [local.hub_cidr]

        subnets = {
          hub_shared = {
            name                      = "snet-hub-shared"
            address_prefixes          = [local.hub_mgmt_cidr]
            route_table_key_reference = "hub_user_subnets"
          }
        }

        ########## Azure Firewall (2 Data-Plane Public IPs + Management IP) ##########
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

        ########## Firewall Policy & Rules ##########
        firewall_policy = {
          sku = "Basic"
          base_policy = {
            rule_collection_groups = {
              default = {
                priority = 100

                # 1. DNAT: Expose eShop web app publicly to the whole world (*) on 2nd PIP
                #    Finance web has NO public DNAT rule so it is unreachable from the internet.
                nat_rule_collections = {
                  public_eshop_dnat = {
                    priority = 100
                    action   = "Dnat"
                    rules = {
                      eshop_http_to_world = {
                        protocols             = ["TCP"]
                        source_addresses      = ["*"]
                        destination_addresses = [azurerm_public_ip.fw_data_2.ip_address]
                        destination_ports     = ["80"]
                        translated_address    = local.eshop_web_ip
                        translated_port       = "80"
                      }
                      eshop_https_to_world = {
                        protocols             = ["TCP"]
                        source_addresses      = ["*"]
                        destination_addresses = [azurerm_public_ip.fw_data_2.ip_address]
                        destination_ports     = ["443"]
                        translated_address    = local.eshop_web_ip
                        translated_port       = "443"
                      }
                    }
                  }
                }

                # 2. Network rules:
                #    - Finance web ONLY accessible from P2S VPN clients (172.16.0.0/24)
                #    - eShop web accessible from anywhere (*) on ports 80/443
                #    - Outbound internet access for workloads
                network_rule_collections = {
                  finance_vpn_only = {
                    priority = 200
                    action   = "Allow"
                    rules = {
                      vpn_to_finance_web = {
                        protocols             = ["TCP"]
                        source_addresses      = [local.vpn_client_cidr]
                        destination_addresses = [local.finance_web_ip]
                        destination_ports     = ["80", "443"]
                      }
                    }
                  }

                  eshop_public_access = {
                    priority = 210
                    action   = "Allow"
                    rules = {
                      world_to_eshop_web = {
                        protocols             = ["TCP"]
                        source_addresses      = ["*"]
                        destination_addresses = [local.eshop_web_ip]
                        destination_ports     = ["80", "443"]
                      }
                    }
                  }

                  outbound_internet = {
                    priority = 300
                    action   = "Allow"
                    rules = {
                      spokes_to_internet = {
                        protocols             = ["TCP", "UDP"]
                        source_addresses      = [local.finance_cidr, local.eshop_cidr, local.hub_mgmt_cidr]
                        destination_addresses = ["*"]
                        destination_ports     = ["80", "443", "53"]
                      }
                    }
                  }
                }

                # 3. Application rules: Microsoft / Azure updates & auth over HTTPS
                application_rule_collections = {
                  allow_fqdn = {
                    priority = 400
                    action   = "Allow"
                    rules = {
                      ms_and_azure = {
                        source_addresses = [local.finance_cidr, local.eshop_cidr, local.hub_mgmt_cidr]
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

        ########## Routing: force spoke/hub traffic through Firewall ##########
        route_table_name_user_subnets = "rt-hub-user-subnets-${random_string.suffix.result}"
        route_table_entries_user_subnets = {
          default_via_firewall = {
            address_prefix        = "0.0.0.0/0"
            next_hop_type         = "VirtualAppliance"
            next_hop_in_ip_address = "use_firewall_private_ip"
          }
          to_finance = {
            address_prefix        = local.finance_cidr
            next_hop_type         = "VirtualAppliance"
            next_hop_in_ip_address = "use_firewall_private_ip"
          }
          to_eshop = {
            address_prefix        = local.eshop_cidr
            next_hop_type         = "VirtualAppliance"
            next_hop_in_ip_address = "use_firewall_private_ip"
          }
          to_vpn_clients = {
            address_prefix        = local.vpn_client_cidr
            next_hop_type         = "VirtualAppliance"
            next_hop_in_ip_address = "use_firewall_private_ip"
          }
        }

        ########## Enabled / Disabled Hub Components ##########
        enabled_resources = {
          firewall                = true
          nat_gateway             = false
          bastion                 = false
          virtual_network_gateway = true
          private_dns_zones       = false
          private_dns_resolver    = false
          ddos_protection_plan    = false
        }
      }

      ########## Point-to-Site (P2S) VPN Gateway (Cheaper Basic SKU) ##########
      virtual_network_gateways = {
        subnet_address_prefix = local.gw_subnet_cidr
        vpn = {
          name     = "vgw-hub-p2s-${random_string.suffix.result}"
          sku      = "Basic"
          type     = "Vpn"
          vpn_type = "RouteBased"
          ip_configurations = {
            primary = {
              public_ip_name = "pip-vgw-p2s-${random_string.suffix.result}"
            }
          }
          vpn_client_configuration = {
            address_space = [local.vpn_client_cidr]
            vpn_protocols = ["IkeV2"]
            root_certificate = [
              {
                name             = "p2s-root-cert"
                public_cert_data = "REPLACE_WITH_BASE64_ROOT_CERT"
              }
            ]
          }
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
# SPOKE 1 – vnet-bu-finance (protected by Azure Firewall via UDR)
###############################################################################
module "spoke_finance" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.9"

  name                = "vnet-bu-finance"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  address_spaces      = [local.finance_cidr]
  enable_telemetry    = false
  tags                = local.common_tags

  subnets = {
    app = {
      name                    = "snet-finance-app"
      address_prefixes        = [local.spoke_finance_subnet_cidr]
      route_table_resource_id = module.connectivity_hub_and_spoke.route_table_resource_ids_by_hub_key["primary"].user_subnets
    }
  }
}

###############################################################################
# SPOKE 2 – vnet-bu-eshop (protected by Azure Firewall via UDR)
###############################################################################
module "spoke_eshop" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.9"

  name                = "vnet-bu-eshop"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  address_spaces      = [local.eshop_cidr]
  enable_telemetry    = false
  tags                = local.common_tags

  subnets = {
    app = {
      name                    = "snet-eshop-app"
      address_prefixes        = [local.spoke_eshop_subnet_cidr]
      route_table_resource_id = module.connectivity_hub_and_spoke.route_table_resource_ids_by_hub_key["primary"].user_subnets
    }
  }
}

###############################################################################
# Hub <-> Spoke Peerings
###############################################################################
module "peering_hub_finance" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/peering"
  version = "~> 0.9"

  virtual_network = {
    resource_id = module.connectivity_hub_and_spoke.virtual_network_resource_ids["primary"]
  }
  remote_virtual_network = {
    resource_id = module.spoke_finance.resource_id
  }
  name                         = "peer-hub-to-bu-finance"
  remote_peering_name          = "peer-bu-finance-to-hub"
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
  allow_virtual_network_access = true
  peer_complete_vnets          = true
}

module "peering_hub_eshop" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/peering"
  version = "~> 0.9"

  virtual_network = {
    resource_id = module.connectivity_hub_and_spoke.virtual_network_resource_ids["primary"]
  }
  remote_virtual_network = {
    resource_id = module.spoke_eshop.resource_id
  }
  name                         = "peer-hub-to-bu-eshop"
  remote_peering_name          = "peer-bu-eshop-to-hub"
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
  allow_virtual_network_access = true
  peer_complete_vnets          = true
}

###############################################################################
# Outputs
###############################################################################
output "hub_vnet_id" {
  value = module.connectivity_hub_and_spoke.virtual_network_resource_ids["primary"]
}

output "firewall_private_ip" {
  value = module.connectivity_hub_and_spoke.firewall_private_ip_addresses["primary"]
}

output "firewall_public_ips" {
  value = module.connectivity_hub_and_spoke.firewall_public_ip_addresses["primary"]
}

output "spoke_vnet_ids" {
  value = {
    finance = module.spoke_finance.resource_id
    eshop   = module.spoke_eshop.resource_id
  }
}