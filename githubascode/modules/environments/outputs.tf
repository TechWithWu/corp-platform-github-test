output "environments" {
  description = "Map of all provisioned GitHub repository environment resources"
  value       = github_repository_environment.this
}

output "environment_keys" {
  description = "List of repository:environment keys provisioned"
  value       = keys(github_repository_environment.this)
}
