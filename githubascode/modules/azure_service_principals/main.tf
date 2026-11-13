# ---------------------------------------------------------------------------------------------------------------------
# AZURE SERVICE PRINCIPALS MODULE
# Manages Azure AD Applications and Service Principals based on config/azure-identity/service_principals.csv
# ---------------------------------------------------------------------------------------------------------------------

data "azuread_client_config" "current" {}
data "azurerm_client_config" "current" {}

# 1. Create Azure AD Applications
resource "azuread_application" "this" {
  for_each = var.service_principals

  display_name = each.value.name
  notes        = each.value.purpose != "" ? each.value.purpose : null
}

# 2. Create Corresponding Azure AD Service Principals
resource "azuread_service_principal" "this" {
  for_each = var.service_principals

  client_id                    = azuread_application.this[each.key].client_id
  description                  = each.value.purpose != "" ? each.value.purpose : null
  app_role_assignment_required = false
}
