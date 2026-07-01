resource "azurerm_cognitive_deployment" "this" {
  name                 = var.name
  cognitive_account_id = var.cognitive_account_id
  dynamic_throttling_enabled = var.dynamic_throttling_enabled
  rai_policy_name = var.rai_policy_name
  version_upgrade_option = var.version_upgrade_option 

  model {
    format  = var.model.format
    name    = var.model.name
    version = var.model.version
  }

  sku {
    name     = var.scale.type
    capacity = var.scale.capacity
    family   = var.scale.family
    size     = var.scale.size
    tier     = var.scale.tier
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
