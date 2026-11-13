# GitHub Branch Protection Module

Applies simple, standardized branch protection rules across repositories:
- Mandatory Pull Requests with 1+ approvals
- Code Owners review required
- Stale review dismissal on new commits
- Linear commit history enforcement
- Force push & branch deletion blocks
- Administrator enforcement (`enforce_admins = true`)

## Usage

```hcl
module "branch_protection" {
  source           = "./modules/branch_protection"
  repository_names = module.repositories.repository_names
  branch           = "main"
}
```
