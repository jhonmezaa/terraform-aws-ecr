################################################################################
# Private Repository Outputs
################################################################################

output "repository_arns" {
  description = "Map of repository keys to repository ARNs"
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "repository_names" {
  description = "Map of repository keys to repository names"
  value       = { for k, v in aws_ecr_repository.this : k => v.name }
}

output "repository_urls" {
  description = "Map of repository keys to repository URLs"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_registry_ids" {
  description = "Map of repository keys to registry IDs"
  value       = { for k, v in aws_ecr_repository.this : k => v.registry_id }
}

################################################################################
# Public Repository Outputs
################################################################################

output "public_repository_arns" {
  description = "Map of public repository keys to repository ARNs"
  value       = { for k, v in aws_ecrpublic_repository.this : k => v.arn }
}

output "public_repository_uris" {
  description = "Map of public repository keys to repository URIs"
  value       = { for k, v in aws_ecrpublic_repository.this : k => v.repository_uri }
}

output "public_repository_registry_ids" {
  description = "Map of public repository keys to registry IDs"
  value       = { for k, v in aws_ecrpublic_repository.this : k => v.registry_id }
}

################################################################################
# Registry Outputs
################################################################################

output "registry_scanning_configuration" {
  description = "The registry scanning configuration"
  value       = try(aws_ecr_registry_scanning_configuration.this[0], null)
}

output "registry_pull_through_cache_rules" {
  description = "Map of pull through cache rule keys to their configurations"
  value       = { for k, v in aws_ecr_pull_through_cache_rule.this : k => v }
}

################################################################################
# Summary Outputs
################################################################################

output "repositories_summary" {
  description = "Comprehensive summary of all private ECR repositories"
  value = {
    for k, v in aws_ecr_repository.this : k => {
      name                  = v.name
      arn                   = v.arn
      url                   = v.repository_url
      registry_id           = v.registry_id
      image_tag_mutability  = v.image_tag_mutability
      encryption_type       = v.encryption_configuration[0].encryption_type
      scan_on_push          = v.image_scanning_configuration[0].scan_on_push
      has_lifecycle_policy  = contains(keys(aws_ecr_lifecycle_policy.this), k)
      has_repository_policy = contains(keys(aws_ecr_repository_policy.this), k)
    }
  }
}

output "public_repositories_summary" {
  description = "Comprehensive summary of all public ECR repositories"
  value = {
    for k, v in aws_ecrpublic_repository.this : k => {
      name        = v.repository_name
      arn         = v.arn
      uri         = v.repository_uri
      registry_id = v.registry_id
    }
  }
}
