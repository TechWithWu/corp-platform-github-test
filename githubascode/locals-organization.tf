# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VALUES - CENTRALIZED CSV CONFIGURATION PARSING
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Parse Organization Members (config/members.csv)
  members_raw = csvdecode(file("${local.config_path}/members.csv"))
  members_data = {
    for m in local.members_raw : m.username => {
      role = try(m.role, "member")
    } if trimspace(try(m.username, "")) != ""
  }
}
