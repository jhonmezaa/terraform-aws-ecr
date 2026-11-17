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
    "ap-east-2"      = "ape2"
    "ap-southeast-5" = "apse5"
    "ap-southeast-6" = "apse6"
    "ap-southeast-7" = "apse7"
    "mx-central-1"   = "mxc1"
  }

  # Effective region: explicit var.region (provider v6 per-resource region) or provider region
  region = coalesce(var.region, data.aws_region.current.region)

  # Determine region prefix (use provided or derive from current region)
  # Falls back to the full region name for regions not present in the map
  region_prefix = var.region_prefix != null ? var.region_prefix : lookup(
    local.region_prefix_map,
    local.region,
    local.region
  )

  # Name prefix: includes region prefix when use_region_prefix is true
  name_prefix = var.use_region_prefix ? "${local.region_prefix}-" : ""

  # Account ID for policy defaults
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  ############################################################################
  # Private Repository Naming and Filtering
  ############################################################################

  # Generate repository names following monorepo convention (overridable with `name`)
  repository_names = {
    for k, v in var.repositories :
    k => coalesce(v.name, "${local.name_prefix}ecr-${var.account_name}-${var.project_name}-${k}")
  }

  ############################################################################
  # Public Repository Naming and Filtering
  ############################################################################

  # Public repository names follow a different pattern (no region prefix, ECR Public is global)
  public_repository_names = {
    for k, v in var.public_repositories :
    k => coalesce(v.name, "${var.account_name}-${var.project_name}-${k}")
  }

  ############################################################################
  # Tags
  ############################################################################

  # Tags for private repositories: common -> module-specific -> per-repository -> Name/ManagedBy
  repository_tags = {
    for k, v in var.repositories :
    k => merge(
      var.tags_common,
      {
        RepositoryKey = k
        AccountName   = var.account_name
        ProjectName   = var.project_name
        Region        = local.region
        RegionCode    = local.region_prefix
      },
      v.tags,
      {
        Name      = local.repository_names[k]
        ManagedBy = "Terraform"
      }
    )
  }

  # Tags for public repositories: common -> module-specific -> per-repository -> Name/ManagedBy
  public_repository_tags = {
    for k, v in var.public_repositories :
    k => merge(
      var.tags_common,
      {
        RepositoryKey = k
        AccountName   = var.account_name
        ProjectName   = var.project_name
      },
      v.tags,
      {
        Name      = local.public_repository_names[k]
        ManagedBy = "Terraform"
      }
    )
  }
}
