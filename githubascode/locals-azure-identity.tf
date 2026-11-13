# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VALUES - AZURE IDENTITY CONFIGURATION PARSING
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # 1. Parse Service Principals (config/azure-identity/service_principals.csv)
  service_principals_raw = csvdecode(file("${local.config_path}/azure-identity/service_principals.csv"))
  service_principals_data = {
    for sp in local.service_principals_raw : trimspace(sp.name) => {
      name       = trimspace(sp.name)
      owner_team = trimspace(try(sp.owner_team, ""))
      purpose    = trimspace(try(sp.purpose, ""))
    } if trimspace(try(sp.name, "")) != ""
  }

  # 2. Parse RBAC Role Assignments (config/azure-identity/rbac.csv)
  rbac_raw = csvdecode(file("${local.config_path}/azure-identity/rbac.csv"))
  rbac_assignments_data = {
    for idx, r in local.rbac_raw : "${trimspace(r.sp_name)}:${trimspace(r.role_definition_name)}:${substr(sha256(trimspace(r.scope_ref)), 0, 8)}" => {
      sp_name              = trimspace(r.sp_name)
      scope_type           = trimspace(try(r.scope_type, ""))
      scope_ref            = trimspace(r.scope_ref)
      role_definition_name = trimspace(r.role_definition_name)
      condition_mode       = trimspace(try(r.condition_mode, ""))
      principal_type       = trimspace(try(r.principal_type, "ServicePrincipal"))
      description          = trimspace(try(r.description, ""))
    } if trimspace(try(r.sp_name, "")) != "" && trimspace(try(r.role_definition_name, "")) != ""
  }

  # 3. Parse Federated Credentials (config/azure-identity/federated_credentials.csv)
  federated_credentials_raw = csvdecode(file("${local.config_path}/azure-identity/federated_credentials.csv"))
  federated_credentials_data = {
    for idx, fc in local.federated_credentials_raw : "${trimspace(fc.sp_name)}:${trimspace(fc.repo_name)}:${trimspace(fc.environment)}" => {
      sp_name      = trimspace(fc.sp_name)
      repo_name    = trimspace(fc.repo_name)
      environment  = trimspace(fc.environment)
      subject_type = trimspace(try(fc.subject_type, "environment"))
    } if trimspace(try(fc.sp_name, "")) != "" && trimspace(try(fc.repo_name, "")) != ""
  }
}
