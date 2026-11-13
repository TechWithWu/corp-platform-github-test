variable "environments_variables" {
  description = "Map of variables and secrets parsed from config/environments-variables.csv"
  type = map(object({
    repo        = string
    environment = string
    keytype     = string
    valuetype   = string
    key         = string
    value       = string
  }))
  default = {}
}

variable "repositories" {
  description = "List of repository names to configure repository-level Azure credentials for"
  type        = list(string)
  default     = []
}

variable "azure_credentials" {
  description = "Azure credentials (AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID) from azure_service_principals"
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

variable "secret_references" {
  description = "Map resolving secret reference identifiers to their actual secret values (e.g. from Azure Key Vault or tfvars)"
  type        = map(string)
  default     = {}
}
