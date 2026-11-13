# ---------------------------------------------------------------------------------------------------------------------
# GITHUB MEMBERS MODULE - MANAGES ORGANIZATION MEMBERSHIP ROLES
# ---------------------------------------------------------------------------------------------------------------------

resource "github_membership" "this" {
  for_each = var.members

  username = each.key
  role     = coalesce(each.value.role, "member")
}

data "github_user" "this" {
  for_each = var.members
  username = each.key
  depends_on = [github_membership.this]
}