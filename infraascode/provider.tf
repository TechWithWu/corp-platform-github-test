###############################################################################
# Providers
###############################################################################

provider "azurerm" {
  features {}
  use_oidc = true
}

# ALZ policy library
# - Always pin the library reference to a specific tag.
# - Never use `latest` or `main` in production.
#
# Changing `ref` forces a full re-evaluation of all policy definitions
# and assignments, which frequently results in large destroy/replace plans.
#
# Upgrade procedure:
#   1. Run `terraform plan -refresh-only`
#   2. Open a dedicated PR that changes ONLY this line
#   3. Validate the plan carefully before merging
provider "alz" {
  library_overwrite_enabled = true

  library_references = [
    {
      path = "platform/alz"
      ref  = "2026.04.2" # ← Keep pinned. Update only to a verified tag.
    }
  ]

  # Non-compliance message placeholder substitution.
  # The module default produces awkward phrasing like "is not be compliant".
  # This mapping makes messages read naturally.
  non_compliance_message_substitution_settings = {
    enforcement_mode = {
      default = "Audit"
      override = {
        "Deny"     = "is"
        "Audit"    = "is not"
        "Disabled" = "is not"
      }
    }
  }
}
