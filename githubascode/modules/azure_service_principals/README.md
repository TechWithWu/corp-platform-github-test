# Azure Service Principals Module

Manages Azure AD Applications and Service Principals defined in `config/azure-identity/service_principals.csv`.

## Features
- Creates Azure AD Applications and Enterprise Service Principals.
- Exports Client IDs, Object IDs, Tenant ID, and Subscription ID for downstream modules (RBAC, Federated Identity Credentials, and GitHub Environment/Repository Variables).
