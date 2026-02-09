################################################################################
# Locals
################################################################################

locals {
  # Region prefix mapping for standardized resource naming
  region_prefix_map = {
    "us-east-1"      = "ause1"
    "us-east-2"      = "ause2"
    "us-west-1"      = "ausw1"
    "us-west-2"      = "ausw2"
    "af-south-1"     = "afs1"
    "ap-east-1"      = "ape1"
    "ap-south-1"     = "aps1"
    "ap-south-2"     = "aps2"
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "ap-southeast-3" = "apse3"
    "ap-southeast-4" = "apse4"
    "ap-northeast-1" = "apne1"
    "ap-northeast-2" = "apne2"
    "ap-northeast-3" = "apne3"
    "ca-central-1"   = "cac1"
    "ca-west-1"      = "caw1"
    "eu-central-1"   = "euc1"
    "eu-central-2"   = "euc2"
    "eu-west-1"      = "euw1"
    "eu-west-2"      = "euw2"
    "eu-west-3"      = "euw3"
    "eu-south-1"     = "eus1"
    "eu-south-2"     = "eus2"
    "eu-north-1"     = "eun1"
    "il-central-1"   = "ilc1"
    "me-south-1"     = "mes1"
    "me-central-1"   = "mec1"
    "sa-east-1"      = "sae1"
  }

  # Determine region prefix (use provided or derive from current region)
  region_prefix = var.region_prefix != null ? var.region_prefix : lookup(
    local.region_prefix_map,
    data.aws_region.current.id,
    "unknown"
  )

  # Account ID for policy defaults
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  ############################################################################
  # Private Repository Naming and Filtering
  ############################################################################

  # Generate repository names following monorepo convention
  repository_names = {
    for k, v in var.repositories :
    k => "${local.region_prefix}-ecr-${var.account_name}-${var.project_name}-${k}"
  }

  # Repositories that need a policy attached
  repositories_with_policy = {
    for k, v in var.repositories :
    k => v if v.attach_repository_policy
  }

  # Repositories that need a lifecycle policy
  repositories_with_lifecycle = {
    for k, v in var.repositories :
    k => v if v.create_lifecycle_policy && v.repository_lifecycle_policy != null && v.repository_lifecycle_policy != ""
  }

  ############################################################################
  # Public Repository Naming and Filtering
  ############################################################################

  # Public repository names follow a different pattern (no region prefix, ECR Public is global)
  public_repository_names = {
    for k, v in var.public_repositories :
    k => "${var.account_name}-${var.project_name}-${k}"
  }

  ############################################################################
  # Tags
  ############################################################################

  # Common tags for private repositories
  repository_tags = {
    for k, v in var.repositories :
    k => merge(
      var.tags_common,
      {
        Name          = local.repository_names[k]
        RepositoryKey = k
        AccountName   = var.account_name
        ProjectName   = var.project_name
        ManagedBy     = "Terraform"
        Region        = data.aws_region.current.id
        RegionCode    = local.region_prefix
      },
      v.tags
    )
  }

  # Common tags for public repositories
  public_repository_tags = {
    for k, v in var.public_repositories :
    k => merge(
      var.tags_common,
      {
        Name          = local.public_repository_names[k]
        RepositoryKey = k
        AccountName   = var.account_name
        ProjectName   = var.project_name
        ManagedBy     = "Terraform"
      },
      v.tags
    )
  }
}
