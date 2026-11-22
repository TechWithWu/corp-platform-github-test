###############################################################################
# Spoke Peering Submodule Variables
###############################################################################

variable "hub_virtual_network_name" {
  description = "The name of the primary Hub Virtual Network (optional if hub_virtual_networks is provided)."
  type        = string
  default     = ""
}

variable "hub_resource_group_name" {
  description = "The name of the Resource Group hosting the Hub Virtual Network (optional if hub_virtual_networks is provided)."
  type        = string
  default     = ""
}

variable "hub_virtual_networks" {
  description = "Map of Hub Virtual Networks available for peering, keyed by hub identifier."
  type = map(object({
    name                = string
    resource_group_name = string
    id                  = optional(string, "")
  }))
  default = {}
}

variable "spoke_peers" {
  description = "Map of spoke virtual network configurations for establishing Hub-to-Spoke peering."
  type = map(object({
    spoke_name                   = string
    remote_virtual_network_id    = string
    hub_vnet_key                 = optional(string, "")
    allow_forwarded_traffic      = optional(bool, true)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
    allow_virtual_network_access = optional(bool, true)
  }))
  default = {}
}
