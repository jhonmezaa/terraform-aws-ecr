################################################################################
# Basic ECR Example
# Creates multiple private ECR repositories with default settings
################################################################################

module "ecr" {
  source = "../../ecr"

  account_name = "dev"
  project_name = "myapp"

  repositories = {
    api = {
      image_tag_mutability = "IMMUTABLE"
      image_scan_on_push   = true
    }

    worker = {
      image_tag_mutability = "MUTABLE"
      image_scan_on_push   = true
    }

    frontend = {}
  }

  tags_common = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
