resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  location            = azurerm_cognitive_account.this.location
  name                = coalesce(each.value.name, "pep-${var.name}")
  resource_group_name = coalesce(each.value.resource_group_name, azurerm_cognitive_account.this.resource_group_name)
  subnet_id           = each.value.subnet_resource_id
  tags                = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = coalesce(each.value.private_service_connection_name, "pse-${var.name}")
    private_connection_resource_id = azurerm_cognitive_account.this.id
    subresource_names              = ["account"]
  }
  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = "account"
      subresource_name   = "account"
    }
  }
  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
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
  for_each = local.private_endpoint_application_security_group_associations

  application_security_group_id = each.value.asg_resource_id
  private_endpoint_id           = azurerm_private_endpoint.this[each.value.pe_key].id
}