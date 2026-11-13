# ---------------------------------------------------------------------------------------------------------------------
# ROOT OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "members" {
  description = "List of organization member usernames"
  value       = module.members.usernames
}

output "teams" {
  description = "Map of provisioned teams with their numeric IDs"
  value       = module.teams.team_ids
}

output "repositories" {
  description = "List of repositories created and managed"
  value       = module.repositories.repository_names
}

output "repository_urls" {
  description = "Map of repository names to their GitHub HTML URLs"
  value       = module.repositories.repository_urls
}

output "branch_protections" {
  description = "List of repositories with active branch protection rules"
  value       = module.branch_protection.protected_repositories
}

output "environments" {
  description = "List of repository environment keys provisioned from config/environments.csv"
  value       = module.environments.environment_keys
}
