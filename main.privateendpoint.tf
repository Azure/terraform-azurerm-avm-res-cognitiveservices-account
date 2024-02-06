locals {
  private_dns_zone_id   = length(var.private_endpoints) > 0 ? try(azurerm_private_dns_zone.dns_zone[0].id, data.azurerm_private_dns_zone.dns_zone[0].id) : null
  private_dns_zone_name = length(var.private_endpoints) > 0 ? try(azurerm_private_dns_zone.dns_zone[0].name, data.azurerm_private_dns_zone.dns_zone[0].name) : null
}

resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  location            = azurerm_cognitive_account.this.location
  name                = coalesce(each.value.name, "pep-${var.name}")
  resource_group_name = coalesce(each.value.resource_group_name, azurerm_cognitive_account.this.resource_group_name)
  subnet_id           = each.value.subnet_resource_id
  tags                = each.value.tags

  private_service_connection {
    name                           = coalesce(each.value.private_service_connection_name, "pse-${var.name}")
    private_connection_resource_id = azurerm_cognitive_account.this.id
    is_manual_connection           = false
    subresource_names              = ["account"]
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }
  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      subresource_name   = "account"
      member_name        = "account"
      private_ip_address = ip_configuration.value.private_ip_address
    }
  }
}

locals {
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
}

resource "azurerm_private_endpoint_application_security_group_association" "this" {
  for_each                      = local.private_endpoint_application_security_group_associations
  private_endpoint_id           = azurerm_private_endpoint.this[each.value.pe_key].id
  application_security_group_id = each.value.asg_resource_id
}

resource "azurerm_private_dns_zone" "dns_zone" {
  count = length(var.private_endpoints) > 0 && var.green_field_private_dns_zone != null ? 1 : 0

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
  private_dns_zone_resource_group_name = try(azurerm_private_dns_zone.dns_zone[0].resource_group_name, var.brown_field_private_dns_zone.resource_group_name, null)
  private_endpoint_vnet_keys           = toset([for pe in var.private_endpoints : pe.vnet_key])
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