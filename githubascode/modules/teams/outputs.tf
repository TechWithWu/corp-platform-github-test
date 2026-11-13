output "teams" {
  description = "Map of created github_team resources"
  value       = github_team.this
}

output "team_ids" {
  description = "Map of team name to numeric team ID"
  value       = { for name, t in github_team.this : name => t.id }
}

output "team_slugs" {
  description = "Map of team name to team slug"
  value       = { for name, t in github_team.this : name => t.slug }
}

output "memberships" {
  description = "Map of team membership resources"
  value       = github_team_membership.this
}
