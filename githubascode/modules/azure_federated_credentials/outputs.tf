output "federated_credentials" {
  description = "Map of created azuread_application_federated_identity_credential resources"
  value       = azuread_application_federated_identity_credential.this
}

output "federated_credential_names" {
  description = "List of created federated identity credential display names"
  value       = [for fc in azuread_application_federated_identity_credential.this : fc.display_name]
}
