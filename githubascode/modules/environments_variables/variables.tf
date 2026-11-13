variable "environments_variables" {
  description = "Map of environment and repository variables parsed from config/environments-variables.csv"
  type = map(object({
    repo        = string
    env_or_repo = string
    key         = string
    value       = optional(string, "")
    type        = string
    sp_name     = optional(string, "")
  }))
  default = {}
}

variable "repositories" {
  description = "List of repository names managed in GitHub"
  type        = list(string)
  default     = []
}

variable "azure_credentials" {
  description = "Azure credentials (client_id, tenant_id, subscription_id, client_ids map) from azure_service_principals"
  type = object({
    client_id       = string
    tenant_id       = string
    subscription_id = string
    client_ids      = optional(map(string), {})
  })
  default = {
    client_id       = ""
    tenant_id       = ""
    subscription_id = ""
    client_ids      = {}
  }
}
