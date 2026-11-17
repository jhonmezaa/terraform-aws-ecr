output "repository_urls" {
  description = "Map of repository keys to URLs"
  value       = module.ecr.repository_urls
}

output "repository_arns" {
  description = "Map of repository keys to ARNs"
  value       = module.ecr.repository_arns
}

output "repositories_summary" {
  description = "Summary of all repositories"
  value       = module.ecr.repositories_summary
}

output "registry_scanning_configuration" {
  description = "Registry scanning configuration"
  value       = module.ecr.registry_scanning_configuration
}

output "registry_pull_through_cache_rules" {
  description = "Pull through cache rules"
  value       = module.ecr.registry_pull_through_cache_rules
}

output "public_repository_uris" {
  description = "Map of public repository keys to URIs"
  value       = module.ecr.public_repository_uris
}

output "public_repositories_summary" {
  description = "Summary of all public repositories"
  value       = module.ecr.public_repositories_summary
}
