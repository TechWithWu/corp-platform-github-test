# import.tf
import {
  to = module.repositories.github_repository.this["corp-platform-github"]
  id = "corp-platform-github"
}

import {
  to = module.members.github_membership.this["techwithwu"]
  id = "corp-techwithwu:techwithwu"
}

# Service Principals Import
locals {
  _imp = {
    "sp-github-actions-bootstrap" = { app = "applications/a4a7edba-b6c4-49af-9327-7f99eadea915", sp = "servicePrincipals/ed1a4d22-89b7-40f3-8d30-449fc1c42e6b" }
  }
}
import {
  for_each = local._imp
  id       = each.value.app
  to       = module.azure_service_principals.azuread_application.this[each.key]
}
import {
  for_each = local._imp
  id       = each.value.sp
  to       = module.azure_service_principals.azuread_service_principal.this[each.key]
}