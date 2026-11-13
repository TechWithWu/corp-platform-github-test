output "members" {
  description = "Map of all provisioned GitHub organization memberships"
  value       = github_membership.this
}

output "usernames" {
  description = "List of member usernames added to the organization"
  value       = keys(github_membership.this)
}

output "user_ids" {
  description = "GitHub username (login) -> user id mapping"
  value = { for k, v in data.github_user.this : k => tonumber(v.id) }
}
