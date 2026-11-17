###############################################################################
# Outputs
###############################################################################

output "resource_group_id" {
  description = "The ID of the management resource group."
  value       = azurerm_resource_group.management.id
}

output "resource_group_name" {
  description = "The name of the management resource group."
  value       = azurerm_resource_group.management.name
}

output "resource_group_location" {
  description = "The Azure region of the management resource group."
  value       = azurerm_resource_group.management.location
}

output "log_analytics_workspace_sku" {
  description = "The SKU applied to the Log Analytics Workspace (Free for non-prod, PerGB2018 for prod)."
  value       = lower(var.environment) == "prod" || lower(var.environment) == "production" ? "PerGB2018" : (var.log_analytics_workspace_sku != null && var.log_analytics_workspace_sku != "" ? var.log_analytics_workspace_sku : "Free")
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace."
  value       = var.log_analytics_workspace_name
}

output "automation_account_name" {
  description = "The name of the Azure Automation account."
  value       = var.automation_account_name
}
