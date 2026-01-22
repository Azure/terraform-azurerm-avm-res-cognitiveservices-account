# Data source to read existing private endpoints (if they exist)
# This helps preserve the existing network interface name during migration
data "azapi_resource" "existing_private_endpoints" {
  for_each = var.private_endpoints

  type                   = "Microsoft.Network/privateEndpoints@2024-05-01"
  name                   = each.value.name != null ? each.value.name : "pep-${var.name}"
  parent_id              = coalesce(each.value.resource_group_name, local.resource_group_name) != local.resource_group_name ? "/subscriptions/${split("/", local.parent_id)[2]}/resourceGroups/${each.value.resource_group_name}" : local.parent_id
  response_export_values = ["*"]
  ignore_not_found = true
  depends_on = [local.resource_block]
}

locals {
  # Determine network interface name: use existing if present, otherwise use variable or let module generate
  private_endpoints_with_nic = { for k, v in var.private_endpoints : k => merge(v, {
    network_interface_name = v.network_interface_name != null ? v.network_interface_name : (
      try(data.azapi_resource.existing_private_endpoints[k].output.properties.customNetworkInterfaceName, null) != null && data.azapi_resource.existing_private_endpoints[k].exists ?
      data.azapi_resource.existing_private_endpoints[k].output.properties.customNetworkInterfaceName :
      null
    )
  }) }
}

module "private_endpoint_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.5.0"

  private_endpoints = { for k, v in local.private_endpoints_with_nic : k => merge(v, {
    subresource_name = "account"
  }) }
  private_endpoints_manage_dns_zone_group = var.private_endpoints_manage_dns_zone_group
  private_endpoints_scope                 = local.resource_block.id
  role_assignment_definition_scope        = local.resource_block.id
  role_assignment_name_use_random_uuid    = true
  enable_telemetry                        = var.enable_telemetry
  # Disable other interfaces - only using private endpoints
  customer_managed_key = null
  diagnostic_settings  = null
  lock                 = null
  managed_identities   = null
  role_assignments     = null
  depends_on = [local.resource_block]
}

resource "azapi_resource" "private_endpoints" {
  for_each = var.private_endpoints_manage_dns_zone_group ? module.private_endpoint_interfaces.private_endpoints_azapi : {}

  location                = var.private_endpoints[each.key].location != null ? var.private_endpoints[each.key].location : var.location
  name                    = each.value.name
  parent_id               = coalesce(var.private_endpoints[each.key].resource_group_name, local.resource_group_name) != local.resource_group_name ? "/subscriptions/${split("/", local.parent_id)[2]}/resourceGroups/${var.private_endpoints[each.key].resource_group_name}" : local.parent_id
  type                    = each.value.type
  body                    = each.value.body
  tags                    = var.private_endpoints[each.key].tags
  ignore_missing_property = true
  retry = {
    error_message_regex = ["Account.*state Accepted"]
  }

  lifecycle {
    ignore_changes = [
      body.properties.customDnsConfigs
    ]
  }
}

resource "azapi_resource" "private_endpoints_unmanaged" {
  for_each = !var.private_endpoints_manage_dns_zone_group ? module.private_endpoint_interfaces.private_endpoints_azapi : {}

  location                = var.private_endpoints[each.key].location != null ? var.private_endpoints[each.key].location : var.location
  name                    = each.value.name
  parent_id               = coalesce(var.private_endpoints[each.key].resource_group_name, local.resource_group_name) != local.resource_group_name ? "/subscriptions/${split("/", local.parent_id)[2]}/resourceGroups/${var.private_endpoints[each.key].resource_group_name}" : local.parent_id
  type                    = each.value.type
  body                    = each.value.body
  ignore_missing_property = true
  tags                    = var.private_endpoints[each.key].tags
  retry = {
    error_message_regex = ["Account.*state Accepted"]
  }

  lifecycle {
    ignore_changes = [
      body.properties.customDnsConfigs
    ]
  }
}

resource "azapi_resource" "private_dns_zone_groups" {
  for_each = module.private_endpoint_interfaces.private_dns_zone_groups_azapi

  name      = each.value.name
  parent_id = azapi_resource.private_endpoints[each.key].id
  type      = each.value.type
  body      = each.value.body

  lifecycle {
    # During migration, DNS zone groups may already exist as embedded blocks
    # Ignore differences to allow smooth migration
    ignore_changes = [
      body.properties.privateDnsZoneConfigs
    ]
  }
}

moved {
  from = azurerm_private_endpoint.this
  to   = azapi_resource.private_endpoints
}

moved {
  from = azurerm_private_endpoint.this_unmanaged_dns_zone_groups
  to   = azapi_resource.private_endpoints_unmanaged
}

resource "azapi_resource" "private_endpoint_role_assignments" {
  for_each = module.private_endpoint_interfaces.role_assignments_private_endpoint_azapi

  name      = each.value.name
  parent_id = var.private_endpoints_manage_dns_zone_group ? azapi_resource.private_endpoints[each.value.pe_key].id : azapi_resource.private_endpoints_unmanaged[each.value.pe_key].id
  type      = each.value.type
  body      = each.value.body
}

resource "azapi_resource" "private_endpoint_locks" {
  for_each = module.private_endpoint_interfaces.lock_private_endpoint_azapi

  name      = each.value.name
  parent_id = var.private_endpoints_manage_dns_zone_group ? azapi_resource.private_endpoints[each.value.pe_key].id : azapi_resource.private_endpoints_unmanaged[each.value.pe_key].id
  type      = each.value.type
  body      = each.value.body

  depends_on = [
    azapi_resource.private_dns_zone_groups,
    azapi_resource.private_endpoint_role_assignments
  ]
}
