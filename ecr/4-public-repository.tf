################################################################################
# Public ECR Repositories
################################################################################

resource "aws_ecrpublic_repository" "this" {
  for_each = var.create ? var.public_repositories : {}

  repository_name = local.public_repository_names[each.key]

  dynamic "catalog_data" {
    for_each = each.value.catalog_data != null ? [each.value.catalog_data] : []

    content {
      about_text        = catalog_data.value.about_text
      architectures     = catalog_data.value.architectures
      description       = catalog_data.value.description
      logo_image_blob   = catalog_data.value.logo_image_blob
      operating_systems = catalog_data.value.operating_systems
      usage_text        = catalog_data.value.usage_text
    }
  }

  tags = local.public_repository_tags[each.key]
}

################################################################################
# Public Repository Policy Documents
################################################################################

data "aws_iam_policy_document" "public_repository" {
  for_each = {
    for k, v in var.public_repositories :
    k => v if var.create && v.attach_repository_policy && v.create_repository_policy
  }

  # Read-only access for specified ARNs (or public access)
  statement {
    sid = "PublicReadOnly"

    principals {
      type = "AWS"
      identifiers = coalescelist(
        each.value.repository_read_access_arns,
        ["*"],
      )
    }

    actions = [
      "ecr-public:BatchGetImage",
      "ecr-public:GetDownloadUrlForLayer",
    ]
  }

  # Read-write access for specified ARNs
  dynamic "statement" {
    for_each = length(each.value.repository_read_write_access_arns) > 0 ? [each.value.repository_read_write_access_arns] : []

    content {
      sid = "ReadWrite"

      principals {
        type        = "AWS"
        identifiers = statement.value
      }

      actions = [
        "ecr-public:BatchCheckLayerAvailability",
        "ecr-public:CompleteLayerUpload",
        "ecr-public:InitiateLayerUpload",
        "ecr-public:PutImage",
        "ecr-public:UploadLayerPart",
      ]
    }
  }

  # Custom policy statements
  dynamic "statement" {
    for_each = each.value.repository_policy_statements != null ? each.value.repository_policy_statements : {}

    content {
      sid           = statement.value.sid
      actions       = statement.value.actions
      not_actions   = statement.value.not_actions
      effect        = statement.value.effect
      resources     = statement.value.resources
      not_resources = statement.value.not_resources

      dynamic "principals" {
        for_each = statement.value.principals != null ? statement.value.principals : []

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = statement.value.not_principals != null ? statement.value.not_principals : []

        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = statement.value.conditions != null ? statement.value.conditions : []

        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

################################################################################
# Public Repository Policy Attachment
################################################################################

resource "aws_ecrpublic_repository_policy" "this" {
  for_each = {
    for k, v in var.public_repositories :
    k => v if var.create && v.attach_repository_policy
  }

  repository_name = aws_ecrpublic_repository.this[each.key].repository_name
  policy          = each.value.create_repository_policy ? data.aws_iam_policy_document.public_repository[each.key].json : each.value.repository_policy
}
