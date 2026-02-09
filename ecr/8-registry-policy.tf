################################################################################
# Registry Policy
################################################################################

resource "aws_ecr_registry_policy" "this" {
  count = var.create && var.create_registry_policy ? 1 : 0

  policy = var.registry_policy
}
