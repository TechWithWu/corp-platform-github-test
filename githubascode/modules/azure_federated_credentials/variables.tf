variable "federated_credentials" {
  description = "Map of Azure AD federated credentials configuration parsed from federated_credentials.csv"
  type = map(object({
    sp_name      = string
    repo_name    = string
    environment  = string
    subject_type = optional(string, "environment")
  }))
  default = {}
}

variable "application_object_ids" {
  description = "Map of Service Principal names to Azure AD Application Object IDs"
  type        = map(string)
  default     = {}
}

variable "github_owner" {
  description = "GitHub organization or user name"
  type        = string
}

variable "repository_ids" {
  description = "Map of repository names to repository IDs from the repositories module (establishes explicit module dependency)"
  type        = map(any)
  default     = {}
}

variable "organization_id" {
  description = "Optional GitHub organization ID"
  type        = string
  default     = ""
}
