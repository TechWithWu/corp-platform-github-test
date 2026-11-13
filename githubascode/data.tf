# data for environments reviewers
data "github_user" "environments_reviewers" {
  for_each = toset(local.all_environment_reviewer_user_names)
  username = each.value
}

data "github_team" "environments_reviewers" {
  for_each = toset(local.all_environment_reviewer_team_slugs)
  slug     = each.value
}