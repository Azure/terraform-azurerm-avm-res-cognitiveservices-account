# Data source to read existing private endpoints (if they exist)
# This helps preserve the existing network interface name during migration
data "azapi_resource" "existing_private_endpoints" {
  for_each = var.private_endpoints

  name                   = each.value.name != null ? each.value.name : "pep-${var.name}"
  parent_id              = coalesce(each.value.resource_group_name, local.resource_group_name) != local.resource_group_name ? "/subscriptions/${split("/", local.parent_id)[2]}/resourceGroups/${each.value.resource_group_name}" : local.parent_id
  type                   = "Microsoft.Network/privateEndpoints@2024-05-01"
  ignore_not_found       = true
  response_export_values = ["*"]

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

  # Disable other interfaces - only using private endpoints
  customer_managed_key = null
  diagnostic_settings  = null
  enable_telemetry     = var.enable_telemetry
  lock                 = null
  managed_identities   = null
  private_endpoints = { for k, v in local.private_endpoints_with_nic : k => merge(v, {
    subresource_name = "account"
  }) }
  private_endpoints_manage_dns_zone_group = var.private_endpoints_manage_dns_zone_group
  private_endpoints_scope                 = local.resource_block.id
  role_assignment_definition_scope        = local.resource_block.id
  role_assignment_name_use_random_uuid    = true
  role_assignments                        = null

  depends_on = [local.resource_block]
}

resource "azapi_resource" "private_endpoints" {
  for_each = var.private_endpoints_manage_dns_zone_group ? module.private_endpoint_interfaces.private_endpoints_azapi : {}

  location                = var.private_endpoints[each.key].location != null ? var.private_endpoints[each.key].location : var.location
  name                    = each.value.name
  parent_id               = coalesce(var.private_endpoints[each.key].resource_group_name, local.resource_group_name) != local.resource_group_name ? "/subscriptions/${split("/", local.parent_id)[2]}/resourceGroups/${var.private_endpoints[each.key].resource_group_name}" : local.parent_id
  type                    = each.value.type
  body                    = each.value.body
  create_headers          = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers          = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_missing_property = true
  read_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  retry = {
    error_message_regex = ["Account.*state Accepted"]
  }
  tags           = var.private_endpoints[each.key].tags
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

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
  create_headers          = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers          = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_missing_property = true
  read_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  retry = {
    error_message_regex = ["Account.*state Accepted"]
  }
  tags           = var.private_endpoints[each.key].tags
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  lifecycle {
    ignore_changes = [
      body.properties.customDnsConfigs
    ]
  }
}

resource "azapi_resource" "private_dns_zone_groups" {
  for_each = module.private_endpoint_interfaces.private_dns_zone_groups_azapi

  name           = each.value.name
  parent_id      = azapi_resource.private_endpoints[each.key].id
  type           = each.value.type
  body           = each.value.body
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

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

  name           = each.value.name
  parent_id      = var.private_endpoints_manage_dns_zone_group ? azapi_resource.private_endpoints[each.value.pe_key].id : azapi_resource.private_endpoints_unmanaged[each.value.pe_key].id
  type           = each.value.type
  body           = each.value.body
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

resource "azapi_resource" "private_endpoint_locks" {
  for_each = module.private_endpoint_interfaces.lock_private_endpoint_azapi

  name           = each.value.name
  parent_id      = var.private_endpoints_manage_dns_zone_group ? azapi_resource.private_endpoints[each.value.pe_key].id : azapi_resource.private_endpoints_unmanaged[each.value.pe_key].id
  type           = each.value.type
  body           = each.value.body
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    azapi_resource.private_dns_zone_groups,
    azapi_resource.private_endpoint_role_assignments
  ]
}
