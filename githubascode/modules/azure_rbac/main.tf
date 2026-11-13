# ---------------------------------------------------------------------------------------------------------------------
# AZURE RBAC MODULE
# Manages Azure Role Assignments based on config/azure-identity/rbac.csv
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_role_assignment" "this" {
  for_each = {
    for k, v in var.rbac_assignments : k => v
    if contains(keys(var.service_principal_object_ids), v.sp_name)
  }

  scope                = each.value.scope_ref
  role_definition_name = each.value.role_definition_name
  principal_id         = var.service_principal_object_ids[each.value.sp_name]
  principal_type       = each.value.principal_type != "" ? each.value.principal_type : "ServicePrincipal"
  description          = each.value.description != "" ? each.value.description : null
}
