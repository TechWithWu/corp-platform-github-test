variable "teams" {
  description = "Map of team definitions including name, description, privacy, and members"
  type = map(object({
    description               = optional(string, "")
    privacy                   = optional(string, "closed")
    create_default_maintainer = optional(bool, true)
    members = optional(map(object({
      role = optional(string, "member")
    })), {})
  }))
  default = {}
}
