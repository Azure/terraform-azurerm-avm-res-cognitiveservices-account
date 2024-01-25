locals {
  private_dns_zone_id   = length(var.private_endpoint) > 0 ? try(azurerm_private_dns_zone.dns_zone[0].id, data.azurerm_private_dns_zone.dns_zone[0].id) : null
  private_dns_zone_name = length(var.private_endpoint) > 0 ? try(azurerm_private_dns_zone.dns_zone[0].name, data.azurerm_private_dns_zone.dns_zone[0].name) : null
}

resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoint

  location            = azurerm_cognitive_account.this.location
  name                = each.value.name
  resource_group_name = coalesce(each.value.resource_group_name, azurerm_cognitive_account.this.resource_group_name)
  subnet_id           = var.private_endpoint_subnets[each.value.vnet_key].subnets[each.value.subnet_key].id
  tags                = each.value.tags

  private_service_connection {
    is_manual_connection           = each.value.is_manual_connection
    name                           = each.value.private_service_connection_name
    private_connection_resource_id = azurerm_cognitive_account.this.id
    subresource_names              = var.pe_subresource_names
  }
  dynamic "private_dns_zone_group" {
    for_each = each.value.private_dns_entry_enabled ? ["private_dns_zone_group"] : []

    content {
      name                 = local.private_dns_zone_name
      private_dns_zone_ids = [local.private_dns_zone_id]
    }
  }
}

resource "azurerm_private_dns_zone" "dns_zone" {
  count = length(var.private_endpoint) > 0 && var.green_field_private_dns_zone != null ? 1 : 0

  name                = "privatelink.openai.azure.com"
  resource_group_name = var.green_field_private_dns_zone.resource_group_name
  tags                = var.green_field_private_dns_zone.tags

  dynamic "timeouts" {
    for_each = var.green_field_private_dns_zone.timeouts == null ? [] : [var.green_field_private_dns_zone.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

locals {
  private_dns_zone_resource_group_name = try(azurerm_private_dns_zone.dns_zone[0].resource_group_name, var.brown_field_private_dns_zone.resource_group_name)
  private_endpoint_vnet_keys           = toset([for pe in var.private_endpoint : pe.vnet_key])
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_link" {
  for_each = var.green_field_private_dns_zone == null ? [] : local.private_endpoint_vnet_keys

  name                  = coalesce(var.private_endpoint_subnets[each.value].vnet_dns_zone_link_name, "${local.private_dns_zone_name}-${each.value}")
  private_dns_zone_name = local.private_dns_zone_name
  resource_group_name   = local.private_dns_zone_resource_group_name
  virtual_network_id    = var.private_endpoint_subnets[each.value].vnet_id
  registration_enabled  = false
  tags                  = var.private_endpoint_subnets[each.value].vnet_dns_zone_link_tags
}