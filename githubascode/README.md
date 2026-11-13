# GitHub-as-Code: Enterprise Governance & Infrastructure

Modular Terraform configuration managing GitHub Organization Members, Teams, Repositories, Branch Protection, and Deployment Environments using a centralized CSV configuration pattern.

---

## Centralized Configuration Directory (`/config`)

All definitions are centralized in the `/terraformgithubascode/config/` folder:

```text
/terraformgithubascode/
├── config/
│   ├── members.csv                  # Organization-wide members and roles (member/admin)
│   ├── teams.csv                    # Teams definitions, descriptions, and privacy settings
│   ├── repositories.csv             # Repositories catalog with visibility and feature toggles
│   ├── environments.csv             # Per-repository deployment environments (dev, prod)
│   ├── environments-variables.csv   # Environment & repository variables and reference-backed secrets
│   ├── branch_protection.csv        # Per-repository branch protection policies
│   ├── azure-identity/              # Azure identity and OIDC integration configurations
│   │   ├── service_principals.csv   # Azure AD Application and Service Principal definitions
│   │   ├── rbac.csv                 # Role assignments across subscriptions and resource groups
│   │   └── federated_credentials.csv# GitHub Actions OIDC federated credentials
│   ├── team-members/                # Team member assignment CSVs (contains team, username, role)
│   │   ├── developer-team.csv
│   │   ├── security-team.csv
│   │   ├── qa-team.csv
│   │   └── it-team.csv
│   └── repos-team/                  # Repository access permissions (contains repository, team_name, permission)
│       ├── corp-platform-github.csv
│       └── corp-platform-foundation.csv
├── modules/
│   ├── members/                     # Manages GitHub organization memberships
│   ├── teams/                       # Manages GitHub teams and team membership assignments
│   ├── repositories/                # Provisions repositories and attaches team access
│   ├── branch_protection/           # Enforces branch protection policies
│   ├── environments/                # Provisions deployment environments per repository
│   ├── azure_service_principals/    # Manages Azure AD Apps and Service Principals
│   ├── azure_rbac/                  # Manages Azure RBAC role assignments
│   ├── azure_federated_credentials/ # Manages Azure AD OIDC federated identity credentials
│   └── environments_variables/      # Manages GitHub vars/secrets & repository Azure OIDC variables
├── validation-github.tf             # Enforces referential integrity on repositories, environments, branches, teams, members
├── validation-azure-identity.tf     # Enforces integrity on Azure SP names, RBAC, and federated credential environments
├── versions.tf                      # Terraform >= 1.5.0
├── locals.tf                        # Base local path configuration
├── locals-*.tf                      # Modular CSV parsing into typed maps
├── main.tf                          # Orchestrates modules with dependency graph
├── variables.tf                     # Root variables
└── outputs.tf                       # Exports key resources, IDs, and URLs
```

---

## CSV Configuration File Schemas

### 1. `config/repositories.csv`
Defines repositories and repository feature flags:
```csv
name,description,visibility,auto_init,has_issues,has_wiki,has_projects
corp-platform-github,corp-platform-github,public,true,true,false,false
corp-platform-foundation,corp-platform-foundation,public,true,true,false,false
myapp-api,Application API service repository,public,true,true,false,false
```

### 2. `config/environments.csv`
Defines deployment environments configured per repository:
```csv
repository,environment,can_admins_bypass,prevent_self_review,wait_timer,reviewer_users,reviewer_teams
corp-platform-github,prod,false,false,0,"techwithwu","it-team"
corp-platform-github,dev,false,false,0,"",""
```

### 3. `config/environments-variables.csv`
Defines GitHub environment and repository variables and secrets with dynamic Azure credential resolution:
```csv
repo,env_or_repo,key,value,type,sp_name
corp-platform-github,repo,AZURE_TENANT_ID,,azure_credential,sp-proj001-platform
corp-platform-github,prod,AZURE_CLIENT_ID,,azure_credential,sp-proj001-platform
corp-platform-github,prod,AZURE_SUBSCRIPTION_ID,,azure_credential,sp-proj001-platform
corp-platform-github,prod,env,prod,plaintext,
corp-platform-github,dev,AZURE_TENANT_ID,,azure_credential,sp-proj001-platformdev
corp-platform-github,dev,AZURE_CLIENT_ID,,azure_credential,sp-proj001-platformdev
corp-platform-github,dev,AZURE_SUBSCRIPTION_ID,,azure_credential,sp-proj001-platformdev
corp-platform-github,dev,env,dev,plaintext,
myapp-api,repo,AZURE_TENANT_ID,,azure_credential,sp-proj001-platform
myapp-api,repo,AZURE_CLIENT_ID,,azure_credential,sp-proj001-platform
myapp-api,repo,AZURE_SUBSCRIPTION_ID,,azure_credential,sp-proj001-platform
myapp-api,repo,env,dev,plaintext,
```

- When `type == "azure_credential"`, `AZURE_CLIENT_ID` is resolved from `sp_name`, and `AZURE_TENANT_ID` / `AZURE_SUBSCRIPTION_ID` are resolved from Azure client configurations.
- When `type == "plaintext"`, values are stored directly from the `value` column.
- Scope: `env_or_repo = "repo"` attaches variables at the repository level; setting `env_or_repo` to an environment name (`dev`, `prod`, etc.) creates environment-level variables.

---

## Validation & Plan-Time Enforcement

Preconditions configured via `terraform_data` run during `terraform plan` to catch configuration errors and typos before changes can be applied:

- **Variable Uniqueness**: Each `(repo, env_or_repo, key)` combination in `environments-variables.csv` must be strictly unique; plan will fail with a clear error message if duplicates are detected.
- **Repository Names**: All repository names referenced across `environments.csv`, `branch_protection.csv`, `repos-team/*.csv`, `environments-variables.csv`, and `federated_credentials.csv` must exist in `repositories.csv`.
- **Environment Names**: Only `dev`, `qa`, `test`, and `prod` are permitted in `environments.csv` and `environments-variables.csv` (or `repo`).
- **Branch Names**: Only `main` and `develop` are allowed in `branch_protection.csv`.
- **Team Members & Teams**: All team names in `team-members/*.csv` and `repos-team/*.csv` must exist in `teams.csv`. All usernames in `team-members/*.csv` must exist in `members.csv`.
- **Azure Identity**: All `sp_name` entries in `rbac.csv`, `federated_credentials.csv`, and `environments-variables.csv` must exist in `service_principals.csv`. Environments in `federated_credentials.csv` must be allowed values (`dev`, `qa`, `test`, `prod`, `pull_request`).

---

## Getting Started

```bash
# 1. Initialize Terraform & provider plugins
terraform init

# 2. Validate configuration
terraform validate

# 3. Plan changes (triggers validation assertions)
terraform plan

# 4. Apply configuration
terraform apply
```
