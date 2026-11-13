output "environment_variables" {
  description = "Map of provisioned GitHub environment variables"
  value       = github_actions_environment_variable.env_variable
}

output "environment_secrets" {
  description = "Map of provisioned GitHub environment secrets"
  value       = github_actions_environment_secret.env_secret
  sensitive   = true
}

output "repository_variables" {
  description = "Map of provisioned GitHub repository variables"
  value       = github_actions_variable.repo_variable
}

output "repository_secrets" {
  description = "Map of provisioned GitHub repository secrets"
  value       = github_actions_secret.repo_secret
  sensitive   = true
}
