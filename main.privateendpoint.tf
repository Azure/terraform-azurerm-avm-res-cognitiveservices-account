resource "azurerm_private_endpoint" "private_endpoints" {
  for_each = var.private_endpoints_manage_dns_zone_group ? var.private_endpoints : {}
  name                = each.value.name
  location            = var.private_endpoints[each.key].location != null ? var.private_endpoints[each.key].location : var.location
  resource_group_name = var.resource_group_name
  subnet_id           = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations
    content {
      name = ip_configuration.name
      private_ip_address = ip_configuration.private_ip_address
    }
  }

  private_dns_zone_group {
    name = each.value.private_dns_zone_group_name
    private_dns_zone_ids = each.value.private_dns_zone_resource_ids
  }

  private_service_connection {
    name                           = each.value.name
    private_connection_resource_id = azurerm_cognitive_account.cognitive_account.id
    is_manual_connection           = false
    subresource_names = ["account"]
  }
  tags = var.private_endpoints[each.key].tags
}