variable "rbac_assignments" {
  description = "Map of Azure RBAC role assignments parsed from rbac.csv"
  type = map(object({
    sp_name              = string
    scope_type           = optional(string, "")
    scope_ref            = string
    role_definition_name = string
    condition_mode       = optional(string, "")
    principal_type       = optional(string, "ServicePrincipal")
    description          = optional(string, "")
  }))
  default = {}
}

variable "service_principal_object_ids" {
  description = "Map of Service Principal names to their Azure AD Object IDs"
  type        = map(string)
  default     = {}
}
