output "members" {
  description = "Map of all provisioned GitHub organization memberships"
  value       = github_membership.this
}

output "usernames" {
  description = "List of member usernames added to the organization"
  value       = keys(github_membership.this)
}
