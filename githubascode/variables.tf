# ---------------------------------------------------------------------------------------------------------------------
# ROOT VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

# Note: All core configurations (repositories, environments, branch protections, teams,
# members, and team permissions) are now fully centralized within the `/config` folder CSVs.

variable "default_branch" {
  description = "Default fallback branch pattern for repositories"
  type        = string
  default     = "main"
}

variable "github_owner" {
  type        = string
  description = "GitHub organization or user name"
}