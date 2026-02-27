################################################################################
# Complete ECR Example
# Demonstrates all features: private repos, public repos, lifecycle policies,
# registry scanning, replication, and pull-through cache
################################################################################

locals {
  account_name = "prod"
  project_name = "platform"
}

################################################################################
# ECR Module - Full Configuration
################################################################################

module "ecr" {
  source = "../../ecr"

  account_name = local.account_name
  project_name = local.project_name

  ############################################################################
  # Private Repositories
  ############################################################################

  repositories = {
    # API service with KMS encryption and lifecycle policy
    api = {
      image_tag_mutability = "IMMUTABLE"
      encryption_type      = "KMS"
      kms_key              = aws_kms_key.ecr.arn
      image_scan_on_push   = true
      force_delete         = false

      # Cross-account access
      repository_read_access_arns       = ["arn:aws:iam::123456789012:root"]
      repository_read_write_access_arns = ["arn:aws:iam::987654321098:role/ci-cd-role"]

      # Lifecycle policy - keep last 30 tagged images, expire untagged after 14 days
      create_lifecycle_policy = true
      repository_lifecycle_policy = jsonencode({
        rules = [
          {
            rulePriority = 1
            description  = "Expire untagged images older than 14 days"
            selection = {
              tagStatus   = "untagged"
              countType   = "sinceImagePushed"
              countUnit   = "days"
              countNumber = 14
            }
            action = {
              type = "expire"
            }
          },
          {
            rulePriority = 2
            description  = "Keep only last 30 tagged images"
            selection = {
              tagStatus     = "tagged"
              tagPrefixList = ["v"]
              countType     = "imageCountMoreThan"
              countNumber   = 30
            }
            action = {
              type = "expire"
            }
          }
        ]
      })

      tags = {
        Service = "api"
        Tier    = "backend"
      }
    }

    # Worker service with default encryption
    worker = {
      image_tag_mutability = "IMMUTABLE"
      image_scan_on_push   = true

      create_lifecycle_policy = true
      repository_lifecycle_policy = jsonencode({
        rules = [
          {
            rulePriority = 1
            description  = "Expire untagged images older than 7 days"
            selection = {
              tagStatus   = "untagged"
              countType   = "sinceImagePushed"
              countUnit   = "days"
              countNumber = 7
            }
            action = {
              type = "expire"
            }
          }
        ]
      })

      tags = {
        Service = "worker"
        Tier    = "backend"
      }
    }

    # Frontend with mutable tags (for :latest)
    frontend = {
      image_tag_mutability = "MUTABLE"
      image_scan_on_push   = true

      tags = {
        Service = "frontend"
        Tier    = "frontend"
      }
    }

    # Repo for ML models with Lambda access
    ml-model = {
      image_tag_mutability = "IMMUTABLE"
      image_scan_on_push   = true

      # Lambda access
      repository_lambda_read_access_arns = [
        "arn:aws:lambda:us-east-1:123456789012:function:ml-inference"
      ]

      tags = {
        Service = "ml-model"
        Tier    = "ml"
      }
    }
  }

  ############################################################################
  # Registry Scanning Configuration
  ############################################################################

  manage_registry_scanning_configuration = true
  registry_scan_type                     = "ENHANCED"

  registry_scan_rules = [
    {
      scan_frequency = "SCAN_ON_PUSH"
      filter = [
        {
          filter      = "*"
          filter_type = "WILDCARD"
        }
      ]
    },
    {
      scan_frequency = "CONTINUOUS_SCAN"
      filter = [
        {
          filter      = "prod-*"
          filter_type = "WILDCARD"
        }
      ]
    }
  ]

  ############################################################################
  # Registry Replication Configuration
  ############################################################################

  create_registry_replication_configuration = true

  registry_replication_rules = [
    {
      destinations = [
        {
          region      = "eu-west-1"
          registry_id = data.aws_caller_identity.current.account_id
        },
        {
          region      = "ap-southeast-1"
          registry_id = data.aws_caller_identity.current.account_id
        }
      ]
      repository_filters = [
        {
          filter      = "prod-"
          filter_type = "PREFIX_MATCH"
        }
      ]
    }
  ]

  ############################################################################
  # Pull-Through Cache Rules
  ############################################################################

  registry_pull_through_cache_rules = {
    docker-hub = {
      ecr_repository_prefix = "docker-hub"
      upstream_registry_url = "registry-1.docker.io"
    }
    github = {
      ecr_repository_prefix = "github"
      upstream_registry_url = "ghcr.io"
    }
    ecr-public = {
      ecr_repository_prefix = "ecr-public"
      upstream_registry_url = "public.ecr.aws"
    }
  }

  ############################################################################
  # Common Tags
  ############################################################################

  tags_common = {
    Environment = "production"
    ManagedBy   = "Terraform"
    Team        = "platform"
  }
}

################################################################################
# Supporting Resources
################################################################################

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR repository encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "ecr-encryption-key"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
