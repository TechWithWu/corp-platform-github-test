###############################################################################
# Spoke Peering Submodule Variables
###############################################################################

variable "hub_virtual_network_id" {
  description = "The Azure Resource ID of the centralized Hub Virtual Network."
  type        = string
}

variable "spoke_peers" {
  description = "Map of spoke virtual network configurations for establishing peering connections with the Hub."
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
