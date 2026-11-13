# ---------------------------------------------------------------------------------------------------------------------
# GITHUB CONFIGURATION VALIDATION
# Enforces strict referential integrity during `terraform plan` to catch typos and duplicates across all CSV configs
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Master sets of valid names from source-of-truth CSVs
  valid_repository_names = toset([
    for r in local.repositories_raw : trimspace(r.name)
    if trimspace(try(r.name, "")) != ""
  ])

  valid_team_names = toset([
    for t in local.teams_raw : trimspace(t.name)
    if trimspace(try(t.name, "")) != ""
  ])

  valid_member_usernames = toset([
    for m in local.members_raw : trimspace(m.username)
    if trimspace(try(m.username, "")) != ""
  ])

  allowed_environments = ["dev", "qa", "test", "prod"]
  allowed_branches     = ["main", "develop"]

  # 1. Collect all repository names referenced across other configuration files
  referenced_repos_in_environments = [
    for row in local.environments_raw : trimspace(row.repository)
    if trimspace(try(row.repository, "")) != ""
  ]

  referenced_repos_in_branch_protection = [
    for row in local.branch_protection_raw : trimspace(row.repository)
    if trimspace(try(row.repository, "")) != ""
  ]

  referenced_repos_in_repos_team = [
    for row in local.repo_teams_raw : trimspace(coalesce(try(row.repository, ""), try(row.repository_name, "")))
    if trimspace(coalesce(try(row.repository, ""), try(row.repository_name, ""))) != ""
  ]

  referenced_repos_in_env_variables = [
    for row in local.environments_variables_raw : trimspace(row.repo)
    if trimspace(try(row.repo, "")) != ""
  ]

  referenced_repos_in_federated_credentials = [
    for row in local.federated_credentials_raw : trimspace(row.repo_name)
    if trimspace(try(row.repo_name, "")) != ""
  ]

  all_referenced_repositories = distinct(concat(
    local.referenced_repos_in_environments,
    local.referenced_repos_in_branch_protection,
    local.referenced_repos_in_repos_team,
    local.referenced_repos_in_env_variables,
    local.referenced_repos_in_federated_credentials
  ))

  invalid_repository_names = sort([
    for repo in local.all_referenced_repositories : repo
    if !contains(local.valid_repository_names, repo)
  ])

  # 2. Check Environments in environments.csv and environments-variables.csv (excluding "repo")
  environments_in_environments_csv = [
    for row in local.environments_raw : lower(trimspace(row.environment))
    if trimspace(try(row.environment, "")) != ""
  ]

  environments_in_env_vars_csv = [
    for row in local.environments_variables_raw : lower(trimspace(row.env_or_repo))
    if trimspace(try(row.env_or_repo, "")) != "" && lower(trimspace(row.env_or_repo)) != "repo"
  ]

  all_referenced_environments = distinct(concat(
    local.environments_in_environments_csv,
    local.environments_in_env_vars_csv
  ))

  invalid_environments = sort([
    for env in local.all_referenced_environments : env
    if !contains(local.allowed_environments, env)
  ])

  # 3. Check Branch Protection branch names
  referenced_branches = distinct([
    for row in local.branch_protection_raw : trimspace(try(row.branch, "main"))
    if trimspace(try(row.branch, "")) != ""
  ])

  invalid_branches = sort([
    for b in local.referenced_branches : b
    if !contains(local.allowed_branches, b)
  ])

  # 4. Check Team Members (team must exist in teams.csv, username must exist in members.csv)
  referenced_teams_in_team_members = distinct([
    for row in local.team_members_raw : trimspace(coalesce(try(row.team, ""), try(row.team_name, "")))
    if trimspace(coalesce(try(row.team, ""), try(row.team_name, ""))) != ""
  ])

  invalid_team_members_teams = sort([
    for t in local.referenced_teams_in_team_members : t
    if !contains(local.valid_team_names, t)
  ])

  referenced_users_in_team_members = distinct([
    for row in local.team_members_raw : trimspace(row.username)
    if trimspace(try(row.username, "")) != ""
  ])

  invalid_team_members_users = sort([
    for u in local.referenced_users_in_team_members : u
    if !contains(local.valid_member_usernames, u)
  ])

  # 5. Check Repo-Team associations (repo must exist in repositories.csv, team must exist in teams.csv)
  referenced_teams_in_repo_team = distinct([
    for row in local.repo_teams_raw : trimspace(row.team_name)
    if trimspace(try(row.team_name, "")) != ""
  ])

  invalid_repo_team_teams = sort([
    for t in local.referenced_teams_in_repo_team : t
    if !contains(local.valid_team_names, t)
  ])

  # 6. Check Environment & Repository Variable Uniqueness ("repo,env_or_repo,key" must be unique)
  env_var_definitions = [
    for row in local.environments_variables_raw :
    "${trimspace(row.repo)}:${trimspace(row.env_or_repo)}:${trimspace(row.key)}"
    if trimspace(try(row.repo, "")) != "" && trimspace(try(row.key, "")) != ""
  ]

  duplicate_env_var_definitions = distinct([
    for k in local.env_var_definitions : k
    if length([for item in local.env_var_definitions : item if item == k]) > 1
  ])
}

# ---------------------------------------------------------------------------------------------------------------------
# TERRAFORM PLAN PRECONDITION VALIDATORS (Fail fast on typo or duplicate)
# ---------------------------------------------------------------------------------------------------------------------

resource "terraform_data" "validate_repository_names" {
  lifecycle {
    precondition {
      condition     = length(local.invalid_repository_names) == 0
      error_message = "VALIDATION FAILED: The following repositories referenced in CSV configs do not exist in config/repositories.csv: [${join(", ", local.invalid_repository_names)}]. Please fix typos or add the repository to config/repositories.csv."
    }
  }
}

resource "terraform_data" "validate_environments" {
  lifecycle {
    precondition {
      condition     = length(local.invalid_environments) == 0
      error_message = "VALIDATION FAILED: Allowed environments are strictly [dev, qa, test, prod] (or 'repo' in environments-variables.csv). Found invalid environments: [${join(", ", local.invalid_environments)}]."
    }
  }
}

resource "terraform_data" "validate_branch_protection" {
  lifecycle {
    precondition {
      condition     = length(local.invalid_branches) == 0
      error_message = "VALIDATION FAILED: Allowed branch names for branch protection are strictly [main, develop]. Found invalid branches: [${join(", ", local.invalid_branches)}]."
    }
  }
}

resource "terraform_data" "validate_team_members_teams" {
  lifecycle {
    precondition {
      condition     = length(local.invalid_team_members_teams) == 0
      error_message = "VALIDATION FAILED: The following team names in config/team-members/*.csv do not exist in config/teams.csv: [${join(", ", local.invalid_team_members_teams)}]."
    }
  }
}

resource "terraform_data" "validate_team_members_users" {
  lifecycle {
    precondition {
      condition     = length(local.invalid_team_members_users) == 0
      error_message = "VALIDATION FAILED: The following usernames in config/team-members/*.csv do not exist in config/members.csv: [${join(", ", local.invalid_team_members_users)}]. All team members must be recognized organization members."
    }
  }
}

resource "terraform_data" "validate_repo_team_teams" {
  lifecycle {
    precondition {
      condition     = length(local.invalid_repo_team_teams) == 0
      error_message = "VALIDATION FAILED: The following team names in config/repos-team/*.csv do not exist in config/teams.csv: [${join(", ", local.invalid_repo_team_teams)}]."
    }
  }
}

resource "terraform_data" "validate_environments_variables_no_duplicates" {
  lifecycle {
    precondition {
      condition     = length(local.duplicate_env_var_definitions) == 0
      error_message = "VALIDATION FAILED: Duplicate environment variable definitions detected for (repo, env_or_repo, key): [${join(", ", local.duplicate_env_var_definitions)}]. Each combination of repo, env_or_repo, and key must be strictly unique."
    }
  }
}
