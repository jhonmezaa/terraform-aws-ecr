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
