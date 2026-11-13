variable "members" {
  description = "Map of GitHub usernames to membership configurations (e.g. role: 'member' or 'admin')"
  type = map(object({
    role = optional(string, "member")
  }))
  default = {}
}
