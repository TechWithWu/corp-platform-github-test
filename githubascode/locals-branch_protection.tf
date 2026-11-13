# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VALUES - CENTRALIZED CSV CONFIGURATION PARSING
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Parse Branch Protection Rules per Repository (config/branch_protection.csv)
  branch_protection_raw = csvdecode(file("${local.config_path}/branch_protection.csv"))
  branch_protection_data = {
    for bp in local.branch_protection_raw : "${bp.repository}:${try(bp.branch, "main")}" => {
      repository                      = bp.repository
      branch                          = try(bp.branch, "main")
      enforce_admins                  = try(bp.enforce_admins, "true") == "true"
      required_linear_history         = try(bp.required_linear_history, "true") == "true"
      allows_force_pushes             = try(bp.allows_force_pushes, "false") == "true"
      allows_deletions                = try(bp.allows_deletions, "false") == "true"
      require_conversation_resolution = try(bp.require_conversation_resolution, "true") == "true"
      require_signed_commits          = try(bp.require_signed_commits, "false") == "true"
      dismiss_stale_reviews           = try(bp.dismiss_stale_reviews, "true") == "true"
      require_code_owner_reviews      = try(bp.require_code_owner_reviews, "true") == "true"
      required_approvals              = try(tonumber(bp.required_approvals), 1)
      require_last_push_approval      = try(bp.require_last_push_approval, "true") == "true"
    } if trimspace(try(bp.repository, "")) != ""
  }
}
