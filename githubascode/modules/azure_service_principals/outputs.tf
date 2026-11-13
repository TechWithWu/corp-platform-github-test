output "service_principals" {
  description = "Map of all created azuread_service_principal resources"
  value       = azuread_service_principal.this
}

output "service_principal_names" {
  description = "List of all created service principal names"
  value       = keys(azuread_service_principal.this)
}

output "service_principal_object_ids" {
  description = "Map of service principal name to service principal object_id"
  value       = { for name, sp in azuread_service_principal.this : name => sp.object_id }
}

output "application_object_ids" {
  description = "Map of service principal name to Azure AD application object_id"
  value       = { for name, app in azuread_application.this : name => app.id }
}

output "client_ids" {
  description = "Map of service principal name to Azure Application (Client) ID"
  value       = { for name, app in azuread_application.this : name => app.client_id }
}

output "primary_client_id" {
  description = "Default/primary Client ID (prefers sp-github-actions-bootstrap)"
  value = contains(keys(azuread_application.this), "sp-github-actions-bootstrap") ? (
    azuread_application.this["sp-github-actions-bootstrap"].client_id
  ) : (
    length(keys(azuread_application.this)) > 0 ? values(azuread_application.this)[0].client_id : ""
  )
}

output "tenant_id" {
  description = "Azure Tenant ID (AZURE_TENANT_ID)"
  value = coalesce(
    var.azure_tenant_id,
    try(data.azuread_client_config.current.tenant_id, ""),
    try(data.azurerm_client_config.current.tenant_id, "")
  )
}

output "subscription_id" {
  description = "Azure Subscription ID (AZURE_SUBSCRIPTION_ID)"
  value = coalesce(
    var.azure_subscription_id,
    try(data.azurerm_client_config.current.subscription_id, "")
  )
}
