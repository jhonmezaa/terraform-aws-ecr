################################################################################
# Repository Lifecycle Policy
################################################################################

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = {
    for k, v in var.repositories :
    k => v if var.create && v.create_lifecycle_policy && v.repository_lifecycle_policy != null && v.repository_lifecycle_policy != ""
  }

  repository = aws_ecr_repository.this[each.key].name
  policy     = each.value.repository_lifecycle_policy
}
