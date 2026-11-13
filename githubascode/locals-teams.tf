# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VALUES - CENTRALIZED CSV CONFIGURATION PARSING
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Parse Teams (config/teams.csv) and Team Members (config/team-members/*.csv)
  # Each file in config/team-members is named by team name, and exact team name is read from the 'team' CSV column.
  teams_raw = csvdecode(file("${local.config_path}/teams.csv"))

  team_members_raw = flatten([
    for file in fileset("${local.config_path}/team-members", "*.csv") :
    csvdecode(file("${local.config_path}/team-members/${file}"))
  ])

  team_members_by_team = {
    for t in local.teams_raw : t.name => {
      for row in local.team_members_raw : row.username => {
        role = coalesce(try(row.role, "member"), "member")
      } if trimspace(coalesce(try(row.team, ""), try(row.team_name, ""))) == t.name
      && trimspace(try(row.username, "")) != ""
    }
  }

  teams_data = {
    for t in local.teams_raw : t.name => {
      description               = try(t.description, "")
      privacy                   = try(t.privacy, "closed")
      create_default_maintainer = true
      members                   = lookup(local.team_members_by_team, t.name, {})
    } if trimspace(try(t.name, "")) != ""
  }

}
