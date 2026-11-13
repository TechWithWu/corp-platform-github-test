# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VALUES - CENTRALIZED CSV CONFIGURATION PARSING
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Parse Repositories (config/repositories.csv) & Team Permissions (config/repos-team/*.csv)
  # Each file in config/repos-team is named by repository name, and exact repo name is read from the 'repository' CSV column.
  repositories_raw = csvdecode(file("${local.config_path}/repositories.csv"))

  repo_teams_raw = flatten([
    for file in fileset("${local.config_path}/repos-team", "*.csv") :
    csvdecode(file("${local.config_path}/repos-team/${file}"))
  ])

  repo_teams_by_repo = {
    for r in local.repositories_raw : r.name => {
      for row in local.repo_teams_raw : row.team_name => {
        permission = row.permission
      } if trimspace(coalesce(try(row.repository, ""), try(row.repository_name, ""))) == r.name
      && trimspace(try(row.team_name, "")) != ""
    }
  }

  repositories_data = {
    for r in local.repositories_raw : r.name => {
      description      = try(r.description, "")
      visibility       = try(r.visibility, "public")
      auto_init        = try(r.auto_init, "true") == "true"
      has_issues       = try(r.has_issues, "true") == "true"
      has_wiki         = try(r.has_wiki, "false") == "true"
      has_projects     = try(r.has_projects, "false") == "true"
      team_permissions = lookup(local.repo_teams_by_repo, r.name, {})
    } if trimspace(try(r.name, "")) != ""
  }
}
