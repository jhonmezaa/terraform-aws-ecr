################################################################################
# Common Variables
################################################################################

variable "create" {
  description = "Determines whether resources will be created (affects all resources)"
  type        = bool
  default     = true
}

variable "account_name" {
  description = "Account name for resource naming (e.g., 'prod', 'dev', 'staging')"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming (e.g., 'myapp', 'platform')"
  type        = string
}

variable "region_prefix" {
  description = "Region prefix for naming. If not provided, auto-derived from current AWS region"
  type        = string
  default     = null
}

variable "use_region_prefix" {
  description = "Whether to include the region prefix in resource names. When false, names omit the region prefix."
  type        = bool
  default     = true
}

variable "tags_common" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Private Repository Variables
################################################################################

variable "repositories" {
  description = "Map of private ECR repository configurations. Each key becomes part of the repository name"
  type = map(object({
    # Image tag settings
    image_tag_mutability = optional(string, "IMMUTABLE")

    # Encryption
    encryption_type = optional(string, "AES256")
    kms_key         = optional(string, null)

    # Scanning
    image_scan_on_push = optional(bool, true)

    # Deletion
    force_delete = optional(bool, false)

    # Repository Policy
    attach_repository_policy = optional(bool, true)
    create_repository_policy = optional(bool, true)
    repository_policy        = optional(string, null)

    # Policy - Access ARNs
    repository_read_access_arns        = optional(list(string), [])
    repository_lambda_read_access_arns = optional(list(string), [])
    repository_read_write_access_arns  = optional(list(string), [])

    # Policy - Custom statements
    repository_policy_statements = optional(map(object({
      sid           = optional(string)
      actions       = optional(list(string))
      not_actions   = optional(list(string))
      effect        = optional(string)
      resources     = optional(list(string))
      not_resources = optional(list(string))
      principals = optional(list(object({
        type        = string
        identifiers = list(string)
      })))
      not_principals = optional(list(object({
        type        = string
        identifiers = list(string)
      })))
      conditions = optional(list(object({
        test     = string
        values   = list(string)
        variable = string
      })))
    })), null)

    # Lifecycle Policy
    create_lifecycle_policy     = optional(bool, false)
    repository_lifecycle_policy = optional(string, null)

    # Per-repository tags
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.repositories :
      contains(["MUTABLE", "IMMUTABLE"], v.image_tag_mutability)
    ])
    error_message = "image_tag_mutability must be one of: MUTABLE, IMMUTABLE."
  }

  validation {
    condition = alltrue([
      for k, v in var.repositories :
      contains(["AES256", "KMS"], v.encryption_type)
    ])
    error_message = "encryption_type must be one of: AES256, KMS."
  }

  validation {
    condition = alltrue([
      for k, v in var.repositories :
      v.encryption_type == "KMS" ? v.kms_key != null : true
    ])
    error_message = "When encryption_type is 'KMS', kms_key must be provided."
  }
}

################################################################################
# Public Repository Variables
################################################################################

variable "public_repositories" {
  description = "Map of public ECR repository configurations. Each key becomes part of the repository name"
  type = map(object({
    # Catalog data
    catalog_data = optional(object({
      about_text        = optional(string)
      architectures     = optional(list(string))
      description       = optional(string)
      logo_image_blob   = optional(string)
      operating_systems = optional(list(string))
      usage_text        = optional(string)
    }), null)

    # Repository Policy
    attach_repository_policy = optional(bool, false)
    create_repository_policy = optional(bool, true)
    repository_policy        = optional(string, null)

    # Policy - Access ARNs
    repository_read_access_arns       = optional(list(string), [])
    repository_read_write_access_arns = optional(list(string), [])

    # Policy - Custom statements
    repository_policy_statements = optional(map(object({
      sid           = optional(string)
      actions       = optional(list(string))
      not_actions   = optional(list(string))
      effect        = optional(string)
      resources     = optional(list(string))
      not_resources = optional(list(string))
      principals = optional(list(object({
        type        = string
        identifiers = list(string)
      })))
      not_principals = optional(list(object({
        type        = string
        identifiers = list(string)
      })))
      conditions = optional(list(object({
        test     = string
        values   = list(string)
        variable = string
      })))
    })), null)

    # Per-repository tags
    tags = optional(map(string), {})
  }))
  default = {}
}

################################################################################
# Registry Policy
################################################################################

variable "create_registry_policy" {
  description = "Determines whether a registry policy will be created"
  type        = bool
  default     = false
}

variable "registry_policy" {
  description = "The registry policy document (JSON formatted string)"
  type        = string
  default     = null
}

################################################################################
# Registry Pull Through Cache Rules
################################################################################

variable "registry_pull_through_cache_rules" {
  description = "Map of pull through cache rules to create"
  type = map(object({
    ecr_repository_prefix      = string
    upstream_registry_url      = string
    credential_arn             = optional(string)
    custom_role_arn            = optional(string)
    upstream_repository_prefix = optional(string)
  }))
  default = {}
}

################################################################################
# Registry Scanning Configuration
################################################################################

variable "manage_registry_scanning_configuration" {
  description = "Determines whether the registry scanning configuration will be managed"
  type        = bool
  default     = false
}

variable "registry_scan_type" {
  description = "The scanning type to set for the registry. Can be either 'ENHANCED' or 'BASIC'"
  type        = string
  default     = "ENHANCED"

  validation {
    condition     = contains(["ENHANCED", "BASIC"], var.registry_scan_type)
    error_message = "registry_scan_type must be either 'ENHANCED' or 'BASIC'."
  }
}

variable "registry_scan_rules" {
  description = "One or multiple blocks specifying scanning rules to determine which repository filters are used and at what frequency scanning will occur"
  type = list(object({
    scan_frequency = string
    filter = list(object({
      filter      = string
      filter_type = optional(string, "WILDCARD")
    }))
  }))
  default = null
}

################################################################################
# Registry Replication Configuration
################################################################################

variable "create_registry_replication_configuration" {
  description = "Determines whether a registry replication configuration will be created"
  type        = bool
  default     = false
}

variable "registry_replication_rules" {
  description = "The replication rules for a replication configuration. A maximum of 10 are allowed"
  type = list(object({
    destinations = list(object({
      region      = string
      registry_id = string
    }))
    repository_filters = optional(list(object({
      filter      = string
      filter_type = string
    })))
  }))
  default = null
}
