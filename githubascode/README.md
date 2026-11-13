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
│   ├── branch_protection.csv        # Per-repository branch protection policies
│   ├── team-members/                # Team member assignment CSVs (contains team, username, role)
│   │   ├── developer-team.csv
│   │   ├── security-team.csv
│   │   ├── qa-team.csv
│   │   └── it-team.csv
│   └── repos-team/                  # Repository access permissions (contains repository, team_name, permission)
│       ├── learn-tf-application.csv
│       └── learn-tf-infrastructure.csv
├── modules/
│   ├── members/                     # Manages GitHub organization memberships
│   ├── teams/                       # Manages GitHub teams and team membership assignments
│   ├── repositories/                # Provisions repositories and attaches team access
│   ├── branch_protection/           # Enforces branch protection policies
│   └── environments/                # Provisions deployment environments per repository
├── versions.tf                      # Terraform >= 1.9.0 and integrations/github ~> 6.0
├── locals.tf                        # Automatically parses all config/*.csv files into typed maps
├── main.tf                          # Orchestrates the 5 modules with clean dependency chains
├── variables.tf                     # Root variables
└── outputs.tf                       # Exports key resources, IDs, and URLs
```

---

## CSV Configuration File Schemas

### 1. `config/repositories.csv`
Defines repositories and repository feature flags:
```csv
name,description,visibility,auto_init,has_issues,has_wiki,has_projects
learn-tf-infrastructure,Learn Terraform - Infrastructure repository managed as code,public,true,true,false,false
learn-tf-application,Learn Terraform - Application repository managed as code,public,true,true,false,false
```

### 2. `config/environments.csv`
Defines deployment environments configured per repository:
```csv
repository,environment,can_admins_bypass,prevent_self_review,wait_timer
learn-tf-infrastructure,dev,true,false,0
learn-tf-infrastructure,prod,false,true,0
learn-tf-application,dev,true,false,0
learn-tf-application,prod,false,true,0
```

### 3. `config/branch_protection.csv`
Defines branch protection rules per repository:
```csv
repository,branch,enforce_admins,required_linear_history,allows_force_pushes,allows_deletions,require_conversation_resolution,require_signed_commits,dismiss_stale_reviews,require_code_owner_reviews,required_approvals,require_last_push_approval
learn-tf-infrastructure,main,true,true,false,false,true,false,true,true,1,true
learn-tf-application,main,true,true,false,false,true,false,true,true,1,true
```

Enforced branch protection attributes:
- `enforce_admins = true`
- `required_linear_history = true`
- `allows_force_pushes = false`
- `allows_deletions = false`
- `require_conversation_resolution = true`
- `require_signed_commits = false`
- `required_pull_request_reviews`:
  - `dismiss_stale_reviews = true`
  - `require_code_owner_reviews = true`
  - `required_approving_review_count = 1`
  - `require_last_push_approval = true`

### 4. `config/members.csv`
```csv
username,role
alex-tf-edu,member
terraform-education1,member
```

### 5. `config/teams.csv`
```csv
name,description,privacy
Security Team,Security Team ,closed
Developer Team,Developer Team ,closed
QA Team,Quality Assurance Team ,closed
IT Team,Infrastructure Team ,closed
```

### 6. `config/repos-team/<repository-name>.csv`
File is named after the repository (e.g. `learn-tf-infrastructure.csv`), and exact repository name is read from the `repository` column:
```csv
repository,team_name,permission
learn-tf-infrastructure,Security Team,maintain
learn-tf-infrastructure,Developer Team,pull
```

### 7. `config/team-members/<team-name>.csv`
File is named after the team (e.g. `security-team.csv`), and exact team name is read from the `team` column:
```csv
team,username,role
Security Team,alex-tf-edu,member
```

---

## Getting Started

```bash
# 1. Initialize Terraform & provider plugins
terraform init

# 2. Validate configuration
terraform validate

# 3. Plan changes
terraform plan

# 4. Apply configuration
terraform apply
```
