# Azure RBAC Module

Manages Azure Role-Based Access Control (RBAC) role assignments defined in `config/azure-identity/rbac.csv`.

## Features
- Maps Azure Service Principals to roles across Management Groups, Subscriptions, and Resource Groups.
- Connects directly to the object IDs provisioned by the `azure_service_principals` module.
