# 1. Organization Members Module
# Manages organization-level memberships and roles from config/members.csv
module "members" {
  source  = "./modules/members"
  members = local.members_data
}

# 2. Teams & Team Memberships Module
# Manages team creation and member assignments from config/teams.csv and config/team-members/*.csv
module "teams" {
  source = "./modules/teams"
  teams  = local.teams_data

  depends_on = [module.members]
}

# 3. Repositories & Team Access Module
# Manages repository provisioning and team access from config/repositories.csv and config/repos-team/*.csv
module "repositories" {
  source       = "./modules/repositories"
  repositories = local.repositories_data
  team_ids     = module.teams.team_ids

  depends_on = [module.teams]
}

# 4. Branch Protection Module
# Enforces branch protection rules based on each repository name from config/branch_protection.csv
module "branch_protection" {
  source             = "./modules/branch_protection"
  branch_protections = local.branch_protection_data

  depends_on = [module.repositories]
}

# 5. Environments Setup Module
# Provisions deployment environments based on each repository name from config/environments.csv
module "environments" {
  source       = "./modules/environments"
  environments = local.environments_data

  depends_on = [module.repositories]
}
