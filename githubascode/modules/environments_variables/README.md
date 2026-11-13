# Environments Variables Module

Manages GitHub Environment and Repository Variables and Secrets driven by `config/environments-variables.csv`.

## CSV Schema
`repo,env_or_repo,key,value,type,sp_name`

## Features
- Dynamic Azure Credentials: when `type == "azure_credential"`, values for `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` are automatically resolved from the `azure_service_principals` module based on `sp_name`.
- Target Scope: `env_or_repo == "repo"` creates repository-level variables, while `env_or_repo` set to an environment name (`dev`, `prod`, etc.) creates environment-level variables.
- Direct Values: when `type == "plaintext"`, values are written directly without secret reference lookups.
