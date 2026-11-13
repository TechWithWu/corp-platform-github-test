# ---------------------------------------------------------------------------------------------------------------------
# GITHUB BRANCH PROTECTION MODULE - ENFORCES PER-REPOSITORY GOVERNANCE RULES
# ---------------------------------------------------------------------------------------------------------------------

resource "github_branch_protection" "this" {
  for_each = var.branch_protections

  repository_id                   = each.value.repository
  pattern                         = coalesce(each.value.branch, "main")
  enforce_admins                  = coalesce(each.value.enforce_admins, true)
  required_linear_history         = coalesce(each.value.required_linear_history, true)
  allows_force_pushes             = coalesce(each.value.allows_force_pushes, false)
  allows_deletions                = coalesce(each.value.allows_deletions, false)
  require_conversation_resolution = coalesce(each.value.require_conversation_resolution, true)
  # checkov:skip=CKV_GIT_6: can be adjusted by parameter, but default is false to avoid unnecessary friction for developers
  require_signed_commits          = coalesce(each.value.require_signed_commits, false)

  required_pull_request_reviews {
    dismiss_stale_reviews           = coalesce(each.value.dismiss_stale_reviews, true)
    require_code_owner_reviews      = coalesce(each.value.require_code_owner_reviews, true)
    # checkov:skip=CKV_GIT_5: can be adjusted by parameter
    required_approving_review_count = coalesce(each.value.required_approvals, 2)
    require_last_push_approval      = coalesce(each.value.require_last_push_approval, true)
  }
}
