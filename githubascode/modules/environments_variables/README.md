# Environments Variables Module

Manages GitHub Environment and Repository Variables and Secrets defined in `config/environments-variables.csv`.

## Features
- Manages environment variables and secrets, as well as repository-level variables and secrets.
- Supports reference-based secret storage so plaintext secrets are never committed directly to CSV files.
- Automatically stores `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` at the repository level with dependency on `azure_service_principals`.
