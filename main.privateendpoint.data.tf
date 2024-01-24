data "azurerm_private_dns_zone" "dns_zone" {
  count = length(var.private_endpoint) > 0 && var.brown_field_private_dns_zone != null ? 1 : 0

  name                = var.brown_field_private_dns_zone.name
  resource_group_name = var.brown_field_private_dns_zone.resource_group_name
}