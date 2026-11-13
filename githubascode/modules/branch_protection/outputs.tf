output "branch_protections" {
  description = "Map of created branch protection rules"
  value       = github_branch_protection.this
}

output "protected_repositories" {
  description = "List of repositories with active branch protection"
  value       = [for bp in var.branch_protections : bp.repository]
}
