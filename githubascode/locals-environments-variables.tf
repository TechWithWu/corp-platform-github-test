# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VALUES - ENVIRONMENTS & REPOSITORY VARIABLES / SECRETS PARSING
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Parse Environments & Repository Variables/Secrets (config/environments-variables.csv)
  environments_variables_raw = csvdecode(file("${local.config_path}/environments-variables.csv"))
  environments_variables_data = {
    for idx, ev in local.environments_variables_raw : "${trimspace(ev.repo)}:${trimspace(try(ev.environment, ""))}:${trimspace(ev.key)}" => {
      repo        = trimspace(ev.repo)
      environment = trimspace(try(ev.environment, ""))
      keytype     = lower(trimspace(ev.keytype))
      valuetype   = lower(trimspace(ev.valuetype))
      key         = trimspace(ev.key)
      value       = trimspace(ev.value)
    } if trimspace(try(ev.repo, "")) != "" && trimspace(try(ev.key, "")) != ""
  }
}
