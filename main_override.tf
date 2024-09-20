resource "azurerm_cognitive_deployment" "this" {
  dynamic "scale" {
    for_each = [each.value.scale]

    content {
      type     = scale.value.type
      capacity = scale.value.capacity
      family   = scale.value.family
      size     = scale.value.size
      tier     = scale.value.tier
    }
  }
}