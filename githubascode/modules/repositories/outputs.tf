output "repositories" {
  description = "Map of all created github_repository resources"
  value       = github_repository.this
}

output "repository_names" {
  description = "List of all created repository names"
  value       = [for repo in github_repository.this : repo.name]
}

output "repository_ids" {
  description = "Map of repository names to repository IDs"
  value       = { for name, repo in github_repository.this : name => repo.repo_id }
}

output "repository_urls" {
  description = "Map of repository names to HTML URLs"
  value       = { for name, repo in github_repository.this : name => repo.html_url }
}

output "team_repositories" {
  description = "Map of github_team_repository permissions configured"
  value       = github_team_repository.this
}
