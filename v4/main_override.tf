resource "azurerm_cognitive_deployment" "this" {
  dynamic "sku" {
    for_each = [each.value.scale]
    iterator = scale
    content {
      tier     = scale.value.tier
      size     = scale.value.size
      family   = scale.value.family
      capacity = scale.value.capacity
      name     = scale.value.type
    }
  }
}