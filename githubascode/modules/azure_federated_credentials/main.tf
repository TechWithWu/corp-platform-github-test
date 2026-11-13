# ---------------------------------------------------------------------------------------------------------------------
# AZURE FEDERATED CREDENTIALS MODULE
# Manages Azure AD Application Federated Identity Credentials for GitHub Actions OIDC integration
# ---------------------------------------------------------------------------------------------------------------------

resource "azuread_application_federated_identity_credential" "this" {
  for_each = {
    for k, v in var.federated_credentials : k => v
    if contains(keys(var.application_object_ids), v.sp_name)
  }

  application_id = var.application_object_ids[each.value.sp_name]
  display_name   = substr(replace("${each.value.sp_name}-${each.value.repo_name}-${each.value.environment}", "_", "-"), 0, 120)
  description    = "GitHub Actions OIDC subject for ${each.value.repo_name} (${each.value.environment})"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"

  subject = (
    each.value.subject_type == "environment" ? (
      "repo:${var.github_owner}/${each.value.repo_name}:environment:${each.value.environment}"
    ) : (
      each.value.subject_type == "pull_request" ? (
        "repo:${var.github_owner}/${each.value.repo_name}:pull_request"
      ) : (
        each.value.subject_type == "branch" ? (
          "repo:${var.github_owner}/${each.value.repo_name}:ref:refs/heads/${each.value.environment}"
        ) : "repo:${var.github_owner}/${each.value.repo_name}:${each.value.environment}"
      )
    )
  )
}
