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

output "service_principals" {
  description = "List of created Azure Service Principal names"
  value       = module.azure_service_principals.service_principal_names
}

output "azure_tenant_id" {
  description = "Azure Tenant ID used for OIDC authentication"
  value       = module.azure_service_principals.tenant_id
}

output "azure_subscription_id" {
  description = "Azure Subscription ID"
  value       = module.azure_service_principals.subscription_id
}

output "federated_credentials" {
  description = "List of created Azure AD Federated Identity Credentials"
  value       = module.azure_federated_credentials.federated_credential_names
}

output "environment_variables" {
  description = "Map of provisioned GitHub environment variables"
  value       = module.environments_variables.environment_variables
}

output "repository_variables" {
  description = "Map of provisioned GitHub repository variables"
  value       = module.environments_variables.repository_variables
}
