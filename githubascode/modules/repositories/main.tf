# ---------------------------------------------------------------------------------------------------------------------
# GITHUB REPOSITORIES MODULE - MANAGES REPOSITORIES AND TEAM COLLABORATION ACCESS
# ---------------------------------------------------------------------------------------------------------------------

# 1. Create GitHub Repositories
resource "github_repository" "this" {
  for_each = var.repositories

  name         = each.key
  description  = each.value.description
  # checkov:skip=CKV_GIT_1: can be adjusted by parameter
  visibility   = each.value.visibility
  auto_init    = each.value.auto_init
  has_issues   = each.value.has_issues
  has_wiki     = each.value.has_wiki
  has_projects = try(each.value.has_projects, false)

  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = false
  delete_branch_on_merge = true
}

# 2. Flatten Team Repository Access Permissions
locals {
  repo_team_permissions_flattened = flatten([
    for repo_name, repo_cfg in var.repositories : [
      for team_name, perm in try(repo_cfg.team_permissions, {}) : {
        key        = "${repo_name}:${team_name}"
        repo_name  = repo_name
        team_name  = team_name
        permission = perm.permission
      } if contains(keys(var.team_ids), team_name)
    ]
  ])
}

# 3. Assign Team Access to Repositories
resource "github_team_repository" "this" {
  for_each = { for item in local.repo_team_permissions_flattened : item.key => item }

  repository = github_repository.this[each.value.repo_name].name
  team_id    = var.team_ids[each.value.team_name]
  permission = each.value.permission
}
