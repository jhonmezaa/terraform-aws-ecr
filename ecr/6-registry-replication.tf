################################################################################
# Registry Replication Configuration
################################################################################

resource "aws_ecr_replication_configuration" "this" {
  count = var.create && var.create_registry_replication_configuration ? 1 : 0

  replication_configuration {

    dynamic "rule" {
      for_each = var.registry_replication_rules != null ? var.registry_replication_rules : []

      content {
        dynamic "destination" {
          for_each = rule.value.destinations

          content {
            region      = destination.value.region
            registry_id = destination.value.registry_id
          }
        }

        dynamic "repository_filter" {
          for_each = rule.value.repository_filters != null ? rule.value.repository_filters : []

          content {
            filter      = repository_filter.value.filter
            filter_type = repository_filter.value.filter_type
          }
        }
      }
    }
  }
}
