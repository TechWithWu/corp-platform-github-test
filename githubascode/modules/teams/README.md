# GitHub Teams Module

Manages GitHub teams and team member role bindings with privacy controls.

## Usage

```hcl
module "teams" {
  source = "./modules/teams"

  teams = {
    "Security Team" = {
      description = "Security and compliance engineers"
      privacy     = "closed"
      members = {
        "alex-tf-edu" = {
          role = "maintainer"
        }
      }
    }
  }
}
```
