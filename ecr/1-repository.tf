################################################################################
# Private ECR Repositories
################################################################################

resource "aws_ecr_repository" "this" {
  for_each = var.create ? var.repositories : {}

  name                 = local.repository_names[each.key]
  image_tag_mutability = each.value.image_tag_mutability

  encryption_configuration {
    encryption_type = each.value.encryption_type
    kms_key         = each.value.kms_key
  }

  image_scanning_configuration {
    scan_on_push = each.value.image_scan_on_push
  }

  dynamic "image_tag_mutability_exclusion_filter" {
    for_each = each.value.image_tag_mutability_exclusion_filter != null ? each.value.image_tag_mutability_exclusion_filter : []

    content {
      filter      = image_tag_mutability_exclusion_filter.value.filter
      filter_type = image_tag_mutability_exclusion_filter.value.filter_type
    }
  }

  force_delete = each.value.force_delete

  tags = local.repository_tags[each.key]
}
