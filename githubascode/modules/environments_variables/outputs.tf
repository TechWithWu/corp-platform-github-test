output "environment_variables" {
  description = "Map of provisioned GitHub environment variables"
  value       = github_actions_environment_variable.this
}

output "environment_secrets" {
  description = "Map of provisioned GitHub environment secrets"
  value       = github_actions_environment_secret.this
  sensitive   = true
}

output "repository_variables" {
  description = "Map of provisioned GitHub repository variables"
  value       = github_actions_variable.this
}

output "repository_secrets" {
  description = "Map of provisioned GitHub repository secrets"
  value       = github_actions_secret.this
  sensitive   = true
}

output "azure_client_id_variables" {
  description = "Repository-level AZURE_CLIENT_ID variables"
  value       = github_actions_variable.azure_client_id
}

output "azure_tenant_id_variables" {
  description = "Repository-level AZURE_TENANT_ID variables"
  value       = github_actions_variable.azure_tenant_id
}

output "azure_subscription_id_variables" {
  description = "Repository-level AZURE_SUBSCRIPTION_ID variables"
  value       = github_actions_variable.azure_subscription_id
}
