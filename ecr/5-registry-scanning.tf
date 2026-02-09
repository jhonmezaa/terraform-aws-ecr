################################################################################
# Registry Scanning Configuration
################################################################################

resource "aws_ecr_registry_scanning_configuration" "this" {
  count = var.create && var.manage_registry_scanning_configuration ? 1 : 0

  scan_type = var.registry_scan_type

  dynamic "rule" {
    for_each = var.registry_scan_rules != null ? var.registry_scan_rules : []

    content {
      scan_frequency = rule.value.scan_frequency

      dynamic "repository_filter" {
        for_each = rule.value.filter

        content {
          filter      = repository_filter.value.filter
          filter_type = repository_filter.value.filter_type
        }
      }
    }
  }
}
