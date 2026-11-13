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
Defines GitHub environment and repository variables and secrets. Secrets use references rather than plaintext:
```csv
repo,environment,keytype,valuetype,key,value
corp-platform-github,prod,variable,plaintext,TF_LOG,INFO
corp-platform-github,prod,secret,reference,DATABASE_PASSWORD,kv-secret-corp-github-db-pwd
corp-platform-github,dev,variable,plaintext,TF_LOG,DEBUG
```

### 4. `config/azure-identity/service_principals.csv`
Defines Azure AD Applications and Service Principals:
```csv
name,owner_team,purpose
sp-github-actions-bootstrap,platform-team,delegates roles only
sp-proj001-platform,platform-team,provisions proj001 infrastructure
sp-proj001-webapi,proj001-team,deploys webapi code to App Service only
```

### 5. `config/azure-identity/rbac.csv`
Defines Azure RBAC role assignments:
```csv
sp_name,scope_type,scope_ref,role_definition_name,condition_mode,principal_type,description
sp-github-actions-bootstrap,management_group,/providers/Microsoft.Management/managementGroups/mg-platform,Role Based Access Control Administrator,exclude_privileged,ServicePrincipal,bootstrap delegates non-privileged roles
```

### 6. `config/azure-identity/federated_credentials.csv`
Defines GitHub Actions OIDC federated identity credentials:
```csv
sp_name,repo_name,environment,subject_type
sp-github-actions-bootstrap,myapp-api,prod,environment
sp-github-actions-bootstrap,myapp-api,dev,environment
sp-github-actions-bootstrap,myapp-api,pull_request,pull_request
```

---

## Validation & Plan-Time Enforcement

Preconditions configured via `terraform_data` run during `terraform plan` to catch configuration errors and typos before changes can be applied:

- **Repository Names**: All repository names referenced across `environments.csv`, `branch_protection.csv`, `repos-team/*.csv`, `environments-variables.csv`, and `federated_credentials.csv` must exist in `repositories.csv`.
- **Environment Names**: Only `dev`, `qa`, `test`, and `prod` are permitted in `environments.csv` and `environments-variables.csv`.
- **Branch Names**: Only `main` and `develop` are allowed in `branch_protection.csv`.
- **Team Members & Teams**: All team names in `team-members/*.csv` and `repos-team/*.csv` must exist in `teams.csv`. All usernames in `team-members/*.csv` must exist in `members.csv`.
- **Azure Identity**: All `sp_name` entries in `rbac.csv` and `federated_credentials.csv` must exist in `service_principals.csv`. Environments in `federated_credentials.csv` must be allowed values (`dev`, `qa`, `test`, `prod`, `pull_request`).

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
