variable "service_principals" {
  description = "Map of Azure Service Principals configuration parsed from service_principals.csv"
  type = map(object({
    name       = string
    owner_team = optional(string, "")
    purpose    = optional(string, "")
  }))
  default = {}
}

variable "azure_tenant_id" {
  description = "Optional override for Azure Tenant ID. If null, inferred from client config data sources."
  type        = string
  default     = null
}

variable "azure_subscription_id" {
  description = "Optional override for Azure Subscription ID. If null, inferred from client config data sources."
  type        = string
  default     = null
}
