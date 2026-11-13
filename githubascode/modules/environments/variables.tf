variable "environments" {
  description = "Map of environment configurations keyed by repository:environment from CSV"
  type = map(object({
    repository          = string
    environment         = string
    can_admins_bypass   = optional(bool, false)
    prevent_self_review = optional(bool, true)
    wait_timer          = optional(number, 0)
    reviewer_users      = list(string)
    reviewer_teams      = list(string) 
  }))
  default = {}
}
