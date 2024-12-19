resource "azurerm_ai_services" "this" {
  count                              = var.kind == "AIServices" ? 1 : 0
  location                           = var.location
  name                               = var.name
  resource_group_name                = var.resource_group_name
  sku_name                           = var.sku_name
  custom_subdomain_name              = var.custom_subdomain_name
  fqdns                              = var.fqdns
  local_authentication_enabled       = var.local_auth_enabled
  outbound_network_access_restricted = var.outbound_network_access_restricted
  public_network_access              = var.public_network_access_enabled ? "Enabled" : "Disabled"
  tags                               = var.tags

  # dynamic "customer_managed_key" {
  #   for_each = var.customer_managed_key == null ? [] : [var.customer_managed_key]

  #   content {
  #     identity_client_id = customer_managed_key.value.identity_client_id == null ? null : customer_managed_key.value.identity_client_id.client_id
  #     key_vault_key_id   = customer_managed_key.value.key_vault_key_id  //try
  #     managed_hsm_key_id = customer_managed_key.value.managed_hsm_key_id   //try
  #   }
  # }
  dynamic "identity" {
    for_each = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? { this = var.managed_identities } : {}

    content {
      type         = identity.value.system_assigned && length(identity.value.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(identity.value.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
  dynamic "network_acls" {
    for_each = var.network_acls == null ? [] : [var.network_acls]

    content {
      default_action = network_acls.value.default_action
      ip_rules       = network_acls.value.ip_rules

      dynamic "virtual_network_rules" {
        for_each = network_acls.value.virtual_network_rules == null ? [] : network_acls.value.virtual_network_rules

        content {
          subnet_id                            = virtual_network_rules.value.subnet_id
          ignore_missing_vnet_service_endpoint = virtual_network_rules.value.ignore_missing_vnet_service_endpoint
        }
      }
    }
  }
  dynamic "storage" {
    for_each = var.storage == null ? [] : var.storage

    content {
      storage_account_id = storage.value.storage_account_id
      identity_client_id = storage.value.identity_client_id
    }
  }
  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}