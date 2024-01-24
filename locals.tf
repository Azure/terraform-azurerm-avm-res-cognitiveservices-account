locals {
  private_dns_zone_resource_group_name = try(azurerm_private_dns_zone.dns_zone[0].resource_group_name, var.brown_field_private_dns_zone.resource_group_name)
}