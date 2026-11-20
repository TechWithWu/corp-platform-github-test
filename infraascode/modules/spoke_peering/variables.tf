###############################################################################
# Spoke Peering Submodule Variables
###############################################################################

variable "hub_virtual_network_name" {
  description = "The name of the centralized Hub Virtual Network."
  type        = string
}

variable "hub_resource_group_name" {
  description = "The name of the Resource Group hosting the Hub Virtual Network."
  type        = string
}

variable "spoke_peers" {
  description = "Map of spoke virtual network configurations for establishing Hub-to-Spoke peering."
  type = map(object({
    spoke_name                   = string
    remote_virtual_network_id    = string
    allow_forwarded_traffic      = optional(bool, true)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
    allow_virtual_network_access = optional(bool, true)
  }))
  default = {}
}
