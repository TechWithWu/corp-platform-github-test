# GitHub Organization Members Module

Manages GitHub organization memberships declaratively with least-privilege role assignment (`member` or `admin`).

## Usage

```hcl
module "members" {
  source = "./modules/members"

  members = {
    "alex-tf-edu" = {
      role = "member"
    }
    "terraform-education1" = {
      role = "member"
    }
  }
}
```
