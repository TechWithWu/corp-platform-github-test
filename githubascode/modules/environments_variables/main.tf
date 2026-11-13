# ---------------------------------------------------------------------------------------------------------------------
# GITHUB ENVIRONMENTS & REPOSITORY VARIABLES / SECRETS MODULE
# Manages environment/repository variables and secrets from config/environments-variables.csv
# and provisions repository-level Azure OIDC credentials (AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID)
# ---------------------------------------------------------------------------------------------------------------------

# 1. Repository-Level Azure OIDC Credentials (Requirement 7)
resource "github_actions_variable" "azure_client_id" {
  for_each = {
    for repo in var.repositories : repo => (
      lookup(var.azure_credentials.client_ids, repo, var.azure_credentials.client_id)
    ) if (lookup(var.azure_credentials.client_ids, repo, var.azure_credentials.client_id) != "")
  }

  repository    = each.key
  variable_name = "AZURE_CLIENT_ID"
  value         = each.value
}

resource "github_actions_variable" "azure_tenant_id" {
  for_each = {
    for repo in var.repositories : repo => var.azure_credentials.tenant_id
    if var.azure_credentials.tenant_id != ""
  }

  repository    = each.key
  variable_name = "AZURE_TENANT_ID"
  value         = each.value
}

resource "github_actions_variable" "azure_subscription_id" {
  for_each = {
    for repo in var.repositories : repo => var.azure_credentials.subscription_id
    if var.azure_credentials.subscription_id != ""
  }

  repository    = each.key
  variable_name = "AZURE_SUBSCRIPTION_ID"
  value         = each.value
}

# 2. Filter CSV Configurations into distinct typed sets
locals {
  environment_variables = {
    for k, v in var.environments_variables : k => v
    if (v.keytype == "variable" || v.keytype == "var") && v.environment != ""
  }

  environment_secrets = {
    for k, v in var.environments_variables : k => v
    if (v.keytype == "secret" || v.keytype == "secrete") && v.environment != ""
  }

  repository_variables = {
    for k, v in var.environments_variables : k => v
    if (v.keytype == "variable" || v.keytype == "var") && v.environment == ""
  }

  repository_secrets = {
    for k, v in var.environments_variables : k => v
    if (v.keytype == "secret" || v.keytype == "secrete") && v.environment == ""
  }
}

# 3. Environment Variables (Plaintext / Non-secret)
resource "github_actions_environment_variable" "this" {
  for_each = local.environment_variables

  repository    = each.value.repo
  environment   = each.value.environment
  variable_name = each.value.key
  value         = each.value.value
}

# 4. Environment Secrets (Reference resolved or masked)
resource "github_actions_environment_secret" "this" {
  for_each = local.environment_secrets

  repository      = each.value.repo
  environment     = each.value.environment
  secret_name     = each.value.key
  plaintext_value = each.value.valuetype == "reference" ? lookup(var.secret_references, each.value.value, each.value.value) : each.value.value
}

# 5. Repository-level Variables
resource "github_actions_variable" "this" {
  for_each = local.repository_variables

  repository    = each.value.repo
  variable_name = each.value.key
  value         = each.value.value
}

# 6. Repository-level Secrets
resource "github_actions_secret" "this" {
  for_each = local.repository_secrets

  repository      = each.value.repo
  secret_name     = each.value.key
  plaintext_value = each.value.valuetype == "reference" ? lookup(var.secret_references, each.value.value, each.value.value) : each.value.value
}
