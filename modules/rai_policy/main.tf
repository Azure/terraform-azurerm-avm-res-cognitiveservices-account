resource "azurerm_cognitive_account_rai_policy" "this" {
  name                 = var.name
  cognitive_account_id = var.cognitive_account_id
  base_policy_name     = var.base_policy_name
  mode = var.mode
  dynamic "content_filter" {
    for_each = var.content_filters
    content {
      name               = content_filter.value.name
      filter_enabled     = content_filter.value.enabled
      block_enabled      = content_filter.value.blocking
      severity_threshold = content_filter.value.severity_threshold
      source             = content_filter.value.source
    }
  }
  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
