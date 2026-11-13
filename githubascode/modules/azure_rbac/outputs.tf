output "role_assignments" {
  description = "Map of all provisioned azurerm_role_assignment resources"
  value       = azurerm_role_assignment.this
}

output "assigned_roles" {
  description = "List of configured role assignment keys"
  value       = keys(azurerm_role_assignment.this)
}
