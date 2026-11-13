# ---------------------------------------------------------------------------------------------------------------------
# GITHUB TEAMS MODULE - MANAGES TEAMS AND TEAM MEMBERSHIP ASSIGNMENTS
# ---------------------------------------------------------------------------------------------------------------------

# 1. Create GitHub Teams
resource "github_team" "this" {
  for_each = var.teams

  name                      = each.key
  description               = each.value.description
  privacy                   = each.value.privacy
  create_default_maintainer = try(each.value.create_default_maintainer, true)
}

# 2. Flatten Team Memberships
locals {
  team_members_flattened = flatten([
    for team_name, team_cfg in var.teams : [
      for username, member_cfg in try(team_cfg.members, {}) : {
        key       = "${team_name}:${username}"
        team_name = team_name
        username  = username
        role      = coalesce(try(member_cfg.role, "member"), "member")
      }
    ]
  ])
}

# 3. Assign Members to Teams
resource "github_team_membership" "this" {
  for_each = { for item in local.team_members_flattened : item.key => item }

  team_id  = github_team.this[each.value.team_name].id
  username = each.value.username
  role     = each.value.role
}
