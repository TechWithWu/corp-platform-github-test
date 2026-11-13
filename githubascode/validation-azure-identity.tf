# ---------------------------------------------------------------------------------------------------------------------
# AZURE IDENTITY CONFIGURATION VALIDATION
# Enforces referential integrity between service_principals.csv, rbac.csv, federated_credentials.csv, and environments-variables.csv
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Master set of valid service principal names from service_principals.csv
  valid_sp_names = toset([
    for sp in local.service_principals_raw : trimspace(sp.name)
    if trimspace(try(sp.name, "")) != ""
  ])

  # Allowed environments for federated credentials (includes pull_request for PR triggers)
  allowed_fc_environments = ["dev", "qa", "test", "prod", "pull_request"]

  # 1. Validate sp_name in rbac.csv
  referenced_sp_in_rbac = distinct([
    for row in local.rbac_raw : trimspace(row.sp_name)
    if trimspace(try(row.sp_name, "")) != ""
  ])

  invalid_rbac_sp_names = sort([
    for sp in local.referenced_sp_in_rbac : sp
    if !contains(local.valid_sp_names, sp)
  ])

  # 2. Validate sp_name in federated_credentials.csv
  referenced_sp_in_fc = distinct([
    for row in local.federated_credentials_raw : trimspace(row.sp_name)
    if trimspace(try(row.sp_name, "")) != ""
  ])

  invalid_fc_sp_names = sort([
    for sp in local.referenced_sp_in_fc : sp
    if !contains(local.valid_sp_names, sp)
  ])

  # 3. Validate environment in federated_credentials.csv
  referenced_fc_environments = distinct([
    for row in local.federated_credentials_raw : lower(trimspace(row.environment))
    if trimspace(try(row.environment, "")) != ""
  ])

  invalid_fc_environments = sort([
    for env in local.referenced_fc_environments : env
    if !contains(local.allowed_fc_environments, env)
  ])

  # 4. Validate sp_name in environments-variables.csv when type is azure_credential
  referenced_sp_in_env_vars = distinct([
    for row in local.environments_variables_raw : trimspace(row.sp_name)
    if lower(trimspace(try(row.type, ""))) == "azure_credential" && trimspace(try(row.sp_name, "")) != ""
  ])

  invalid_env_vars_sp_names = sort([
    for sp in local.referenced_sp_in_env_vars : sp
    if !contains(local.valid_sp_names, sp)
  ])
}

# ---------------------------------------------------------------------------------------------------------------------
# TERRAFORM PLAN PRECONDITION VALIDATORS (Fail fast on typo)
# ---------------------------------------------------------------------------------------------------------------------

resource "terraform_data" "validate_azure_rbac_sp" {
  lifecycle {
    precondition {
      condition     = length(local.invalid_rbac_sp_names) == 0
      error_message = "VALIDATION FAILED: The following sp_name values in config/azure-identity/rbac.csv do not exist in service_principals.csv: [${join(", ", local.invalid_rbac_sp_names)}]."
    }
  }
}

resource "terraform_data" "validate_azure_federated_credentials_sp" {
  lifecycle {
    precondition {
      condition     = length(local.invalid_fc_sp_names) == 0
      error_message = "VALIDATION FAILED: The following sp_name values in config/azure-identity/federated_credentials.csv do not exist in service_principals.csv: [${join(", ", local.invalid_fc_sp_names)}]."
    }
  }
}

resource "terraform_data" "validate_azure_federated_credentials_env" {
  lifecycle {
    precondition {
      condition     = length(local.invalid_fc_environments) == 0
      error_message = "VALIDATION FAILED: Allowed environments in config/azure-identity/federated_credentials.csv are [dev, qa, test, prod, pull_request]. Found invalid: [${join(", ", local.invalid_fc_environments)}]."
    }
  }
}

resource "terraform_data" "validate_azure_env_vars_sp" {
  lifecycle {
    precondition {
      condition     = length(local.invalid_env_vars_sp_names) == 0
      error_message = "VALIDATION FAILED: The following sp_name values in config/environments-variables.csv do not exist in service_principals.csv: [${join(", ", local.invalid_env_vars_sp_names)}]."
    }
  }
}
