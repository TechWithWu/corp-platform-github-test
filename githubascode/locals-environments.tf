# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VALUES - Environments Configuration Parsing
# ---------------------------------------------------------------------------------------------------------------------

locals {
  environments_raw = csvdecode(file("${local.config_path}/environments.csv"))
  environments_data_raw = {
    for row in local.environments_raw : "${row.repository}:${row.environment}" => {
      repository          = row.repository
      environment         = row.environment
      can_admins_bypass   = try(row.can_admins_bypass, "false") == "true"
      prevent_self_review = try(row.prevent_self_review, "true") == "true"
      wait_timer          = try(tonumber(row.wait_timer), 0)
      reviewer_users = [
        for x in split(";", try(row.reviewer_users, "")) : trimspace(x)
        if trimspace(x) != "" && trimspace(x) != "\"\""
      ]
      reviewer_teams = [
        for x in split(";", try(row.reviewer_teams, "")) : trimspace(x)
        if trimspace(x) != "" && trimspace(x) != "\"\""
      ]
    } if trimspace(try(row.repository, "")) != "" && trimspace(try(row.environment, "")) != ""
  }

  all_environment_reviewer_user_names = sort(distinct(flatten([
    for v in local.environments_data_raw : v.reviewer_users
  ])))

  all_environment_reviewer_team_slugs = sort(distinct(flatten([
    for v in local.environments_data_raw : v.reviewer_teams
  ])))

  user_id_map = { for n in local.all_environment_reviewer_user_names : n => module.members.user_ids[n] }
  team_id_map = { for s in local.all_environment_reviewer_team_slugs : s => module.teams.team_ids[s] }

  environments_data = {
    for k, v in local.environments_data_raw : k => {
      repository          = v.repository
      environment         = v.environment
      can_admins_bypass   = v.can_admins_bypass
      prevent_self_review = v.prevent_self_review
      wait_timer          = v.wait_timer
      reviewer_users      = sort([for u in v.reviewer_users : local.user_id_map[u]])
      reviewer_teams      = sort([for t in v.reviewer_teams : local.team_id_map[t]])
    }
  }
}
