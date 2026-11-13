# 1. Organization Members Module
# Manages organization-level memberships and roles from config/members.csv
module "members" {
  source  = "./modules/members"
  members = local.members_data
}

# 2. Teams & Team Memberships Module
# Manages team creation and member assignments from config/teams.csv and config/team-members/*.csv
module "teams" {
  source = "./modules/teams"
  teams  = local.teams_data

  depends_on = [module.members]
}

# 3. Repositories & Team Access Module
# Manages repository provisioning and team access from config/repositories.csv and config/repos-team/*.csv
module "repositories" {
  source       = "./modules/repositories"
  repositories = local.repositories_data
  team_ids     = module.teams.team_ids

  depends_on = [module.teams]
}

# 4. Branch Protection Module
# Enforces branch protection rules based on each repository name from config/branch_protection.csv
module "branch_protection" {
  source             = "./modules/branch_protection"
  branch_protections = local.branch_protection_data

  depends_on = [module.repositories]
}

# 5. Environments Setup Module
# Provisions deployment environments based on each repository name from config/environments.csv
module "environments" {
  source       = "./modules/environments"
  environments = local.environments_data

  depends_on = [module.repositories, module.teams, module.members]
}

# 6. Azure Service Principals Module
# Provisions Azure AD Applications and Service Principals from config/azure-identity/service_principals.csv
module "azure_service_principals" {
  source                = "./modules/azure_service_principals"
  service_principals    = local.service_principals_data
}

# 7. Azure RBAC Module
# Manages Azure Role Assignments from config/azure-identity/rbac.csv
module "azure_rbac" {
  source                       = "./modules/azure_rbac"
  rbac_assignments             = local.rbac_assignments_data
  service_principal_object_ids = module.azure_service_principals.service_principal_object_ids

  depends_on = [module.azure_service_principals]
}

# 8. Azure Federated Credentials Module
# Manages Azure AD OIDC Federated Credentials for GitHub Actions from config/azure-identity/federated_credentials.csv
# Explicitly depends on module.repositories (requires repository and org context)
module "azure_federated_credentials" {
  source                 = "./modules/azure_federated_credentials"
  federated_credentials  = local.federated_credentials_data
  application_object_ids = module.azure_service_principals.application_object_ids
  github_owner           = var.github_owner
  repository_ids         = module.repositories.repository_ids

  depends_on = [module.repositories, module.azure_service_principals]
}

# 9. GitHub Environments & Repository Variables / Secrets Module
# Manages variables and reference-backed secrets from config/environments-variables.csv
# Depends on azure_service_principals to store repository-level AZURE_CLIENT_ID, AZURE_TENANT_ID, and AZURE_SUBSCRIPTION_ID
module "environments_variables" {
  source                 = "./modules/environments_variables"
  environments_variables = local.environments_variables_data
  repositories           = module.repositories.repository_names
  azure_credentials = {
    client_id       = module.azure_service_principals.primary_client_id
    tenant_id       = module.azure_service_principals.tenant_id
    subscription_id = module.azure_service_principals.subscription_id
    client_ids      = module.azure_service_principals.client_ids
  }

  depends_on = [
    module.azure_service_principals,
    module.environments,
    module.repositories
  ]
}
