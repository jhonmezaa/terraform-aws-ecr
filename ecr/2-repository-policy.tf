################################################################################
# Private Repository Policy Documents
################################################################################

data "aws_iam_policy_document" "repository" {
  for_each = {
    for k, v in var.repositories :
    k => v if var.create && v.attach_repository_policy && v.create_repository_policy
  }

  # Read-only access for specified ARNs
  dynamic "statement" {
    for_each = length(concat(each.value.repository_read_access_arns, each.value.repository_read_write_access_arns)) > 0 ? [1] : []

    content {
      sid = "PrivateReadOnly"

      principals {
        type = "AWS"
        identifiers = concat(
          each.value.repository_read_access_arns,
          each.value.repository_read_write_access_arns
        )
      }

      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:DescribeImageScanFindings",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetLifecyclePolicy",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:GetRepositoryPolicy",
        "ecr:ListImages",
        "ecr:ListTagsForResource",
      ]
    }
  }

  # Default read-only access when no ARNs specified (account root)
  dynamic "statement" {
    for_each = length(concat(each.value.repository_read_access_arns, each.value.repository_read_write_access_arns)) == 0 ? [1] : []

    content {
      sid = "PrivateReadOnly"

      principals {
        type        = "AWS"
        identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
      }

      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:DescribeImageScanFindings",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetLifecyclePolicy",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:GetRepositoryPolicy",
        "ecr:ListImages",
        "ecr:ListTagsForResource",
      ]
    }
  }

  # Lambda read-only access
  dynamic "statement" {
    for_each = length(each.value.repository_lambda_read_access_arns) > 0 ? [1] : []

    content {
      sid = "PrivateLambdaReadOnly"

      principals {
        type        = "Service"
        identifiers = ["lambda.amazonaws.com"]
      }

      actions = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      ]

      condition {
        test     = "StringLike"
        variable = "aws:sourceArn"
        values   = each.value.repository_lambda_read_access_arns
      }
    }
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
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
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
# Private Repository Policy Attachment
################################################################################

resource "aws_ecr_repository_policy" "this" {
  for_each = {
    for k, v in var.repositories :
    k => v if var.create && v.attach_repository_policy
  }

  repository = aws_ecr_repository.this[each.key].name
  policy     = each.value.create_repository_policy ? data.aws_iam_policy_document.repository[each.key].json : each.value.repository_policy
}
