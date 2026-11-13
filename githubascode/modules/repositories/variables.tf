variable "repositories" {
  description = "Map of repositories to create with permissions"
  type = map(object({
    description  = optional(string, "")
    visibility   = optional(string, "private")
    auto_init    = optional(bool, true)
    has_issues   = optional(bool, true)
    has_wiki     = optional(bool, false)
    has_projects = optional(bool, false)
    team_permissions = optional(map(object({
      permission = string
    })), {})
  }))
  default = {}
}

variable "team_ids" {
  description = "Map of team name to team ID for repository team permissions assignment"
  type        = map(string)
  default     = {}
}
