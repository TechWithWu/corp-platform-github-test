# GitHub Environments Module

Sets up isolated CI/CD deployment environments for repositories (e.g. `development`, `staging`, `production`) with deployment safeguards.

## Usage

```hcl
module "environments" {
  source           = "./modules/environments"
  repository_names = module.repositories.repository_names
  environments     = ["development", "staging", "production"]
}
```
