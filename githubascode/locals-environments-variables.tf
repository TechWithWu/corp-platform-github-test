# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VALUES - ENVIRONMENTS & REPOSITORY VARIABLES / SECRETS PARSING
# Schema: repo,env_or_repo,key,value,type,sp_name
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Parse Environments & Repository Variables/Secrets (config/environments-variables.csv)
  environments_variables_raw = csvdecode(file("${local.config_path}/environments-variables.csv"))

  # Map indexed with row number to avoid unhandled Terraform map-key collisions prior to precondition evaluation
  environments_variables_data = {
    for idx, ev in local.environments_variables_raw : "${trimspace(ev.repo)}:${trimspace(ev.env_or_repo)}:${trimspace(ev.key)}#${idx}" => {
      repo        = trimspace(ev.repo)
      env_or_repo = trimspace(ev.env_or_repo)
      key         = trimspace(ev.key)
      value       = trimspace(try(ev.value, ""))
      type        = lower(trimspace(ev.type))
      sp_name     = trimspace(try(ev.sp_name, ""))
    } if trimspace(try(ev.repo, "")) != "" && trimspace(try(ev.key, "")) != ""
  }
}
