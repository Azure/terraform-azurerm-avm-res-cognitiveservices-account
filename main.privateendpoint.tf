locals {
  private_dns_zone_id   = length(var.private_endpoint) > 0 ? try(azurerm_private_dns_zone.dns_zone[0].id, data.azurerm_private_dns_zone.dns_zone[0].id) : null
  private_dns_zone_name = length(var.private_endpoint) > 0 ? try(azurerm_private_dns_zone.dns_zone[0].name, data.azurerm_private_dns_zone.dns_zone[0].name) : null
}

resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoint

  location            = azurerm_cognitive_account.this.location
  name                = each.value.name
  resource_group_name = coalesce(each.value.resource_group_name, azurerm_cognitive_account.this.resource_group_name)
  subnet_id           = each.value.subnet_id
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

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_link" {
  for_each = var.private_endpoint

  name                  = each.value.dns_zone_virtual_network_link_name
  private_dns_zone_name = local.private_dns_zone_name
  resource_group_name   = coalesce(each.value.resource_group_name, local.private_dns_zone_resource_group_name)
  #           0  1              2                                   3              4          5          6               7                 8    9
  # subnet id: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mygroup1/providers/Microsoft.Network/virtualNetworks/myvnet1/subnets/mysubnet1
  # `slice` function's `startindex` is inclusive, while `endindex` is exclusive
  virtual_network_id    = join("/", slice(split("/", each.value.subnet_id), 0, 9))
  registration_enabled  = false
  tags                  = each.value.dns_zone_virtual_network_link_tags
}