# ---------------------------------------------------------------------------------------------------------------------
# GITHUB ENVIRONMENTS & REPOSITORY VARIABLES / SECRETS MODULE
# Manages environment/repository variables and secrets driven by config/environments-variables.csv
# Dynamically resolves Azure credentials (AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID) from azure_service_principals
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Resolve value dynamically based on type (azure_credential vs plaintext)
  resolved_variables = {
    for k, v in var.environments_variables : k => merge(v, {
      resolved_value = (
        v.type == "azure_credential" ? (
          v.key == "AZURE_TENANT_ID" ? var.azure_credentials.tenant_id : (
            v.key == "AZURE_SUBSCRIPTION_ID" ? var.azure_credentials.subscription_id : (
              v.key == "AZURE_CLIENT_ID" ? (
                lookup(var.azure_credentials.client_ids, v.sp_name, var.azure_credentials.client_id)
              ) : lookup(var.azure_credentials.client_ids, v.sp_name, v.value)
            )
          )
        ) : v.value
      )
    })
  }

  # Repository-level variables (env_or_repo == "repo")
  repo_variables = {
    for k, v in local.resolved_variables : k => v
    if lower(v.env_or_repo) == "repo" && !can(regex("secret", v.type))
  }

  # Repository-level secrets (env_or_repo == "repo" and type includes "secret")
  repo_secrets = {
    for k, v in local.resolved_variables : k => v
    if lower(v.env_or_repo) == "repo" && can(regex("secret", v.type))
  }

  # Environment-level variables (env_or_repo != "repo")
  env_variables = {
    for k, v in local.resolved_variables : k => v
    if lower(v.env_or_repo) != "repo" && !can(regex("secret", v.type))
  }

  # Environment-level secrets (env_or_repo != "repo" and type includes "secret")
  env_secrets = {
    for k, v in local.resolved_variables : k => v
    if lower(v.env_or_repo) != "repo" && can(regex("secret", v.type))
  }
}

# 1. Repository-Level Variables
resource "github_actions_variable" "repo_variable" {
  for_each = local.repo_variables

  repository    = each.value.repo
  variable_name = each.value.key
  value         = each.value.resolved_value
}

# 2. Repository-Level Secrets
resource "github_actions_secret" "repo_secret" {
  for_each = local.repo_secrets

  repository      = each.value.repo
  secret_name     = each.value.key
  plaintext_value = each.value.resolved_value
}

# 3. Environment-Level Variables
resource "github_actions_environment_variable" "env_variable" {
  for_each = local.env_variables

  repository    = each.value.repo
  environment   = each.value.env_or_repo
  variable_name = each.value.key
  value         = each.value.resolved_value
}

# 4. Environment-Level Secrets
resource "github_actions_environment_secret" "env_secret" {
  for_each = local.env_secrets

  repository      = each.value.repo
  environment     = each.value.env_or_repo
  secret_name     = each.value.key
  plaintext_value = each.value.resolved_value
}
