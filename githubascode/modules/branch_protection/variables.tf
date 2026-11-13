variable "branch_protections" {
  description = "Map of per-repository branch protection rules from configuration CSV"
  type = map(object({
    repository                      = string
    branch                          = optional(string, "main")
    enforce_admins                  = optional(bool, true)
    required_linear_history         = optional(bool, true)
    allows_force_pushes             = optional(bool, false)
    allows_deletions                = optional(bool, false)
    require_conversation_resolution = optional(bool, true)
    require_signed_commits          = optional(bool, false)
    dismiss_stale_reviews           = optional(bool, true)
    require_code_owner_reviews      = optional(bool, true)
    required_approvals              = optional(number, 1)
    require_last_push_approval      = optional(bool, true)
  }))
  default = {}
}
