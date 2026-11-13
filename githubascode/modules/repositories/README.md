# GitHub Repositories Module

Provisions GitHub repositories with clean security configurations (squash merge enforcement, branch auto-deletion) and team permissions.

## Usage

```hcl
module "repositories" {
  source = "./modules/repositories"

  repositories = {
    "learn-tf-infrastructure" = {
      description = "Infrastructure code repository"
      visibility  = "private"
      team_permissions = {
        "Security Team" = { permission = "maintain" }
        "Developer Team" = { permission = "pull" }
      }
    }
  }

  team_ids = module.teams.team_ids
}
```
