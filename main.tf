resource "random_string" "default_custom_subdomain_name_suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_cognitive_account" "this" {
  kind                                         = var.cognitive_account_kind
  location                                     = var.cognitive_account_location
  name                                         = var.cognitive_account_name
  resource_group_name                          = var.cognitive_account_resource_group_name
  sku_name                                     = var.cognitive_account_sku_name
  custom_question_answering_search_service_id  = var.cognitive_account_custom_question_answering_search_service_id
  custom_question_answering_search_service_key = var.cognitive_account_custom_question_answering_search_service_key
  custom_subdomain_name                        = coalesce(var.cognitive_account_custom_subdomain_name, "azure-cognitive-${random_string.default_custom_subdomain_name_suffix.result}")
  dynamic_throttling_enabled                   = var.cognitive_account_dynamic_throttling_enabled
  fqdns                                        = var.cognitive_account_fqdns
  local_auth_enabled                           = var.cognitive_account_local_auth_enabled
  metrics_advisor_aad_client_id                = var.cognitive_account_metrics_advisor_aad_client_id
  metrics_advisor_aad_tenant_id                = var.cognitive_account_metrics_advisor_aad_tenant_id
  metrics_advisor_super_user_name              = var.cognitive_account_metrics_advisor_super_user_name
  metrics_advisor_website_name                 = var.cognitive_account_metrics_advisor_website_name
  outbound_network_access_restricted           = var.cognitive_account_outbound_network_access_restricted
  public_network_access_enabled                = var.cognitive_account_public_network_access_enabled
  qna_runtime_endpoint                         = var.cognitive_account_qna_runtime_endpoint
  tags                                         = var.cognitive_account_tags

  dynamic "customer_managed_key" {
    for_each = var.cognitive_account_customer_managed_key == null ? [] : [var.cognitive_account_customer_managed_key]
    content {
      key_vault_key_id   = customer_managed_key.value.key_vault_key_id
      identity_client_id = customer_managed_key.value.identity_client_id
    }
  }
  dynamic "identity" {
    for_each = var.cognitive_account_identity == null ? [] : [var.cognitive_account_identity]
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
  dynamic "network_acls" {
    for_each = var.cognitive_account_network_acls == null ? [] : [var.cognitive_account_network_acls]
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
    for_each = var.cognitive_account_storage == null ? [] : var.cognitive_account_storage
    content {
      storage_account_id = storage.value.storage_account_id
      identity_client_id = storage.value.identity_client_id
    }
  }
  dynamic "timeouts" {
    for_each = var.cognitive_account_timeouts == null ? [] : [var.cognitive_account_timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azurerm_cognitive_account_customer_managed_key" "this" {
  count = var.cognitive_account_customer_managed_key == null ? 0 : 1

  cognitive_account_id = azurerm_cognitive_account.this.id
  key_vault_key_id     = var.cognitive_account_customer_managed_key.key_vault_key_id
  identity_client_id   = var.cognitive_account_customer_managed_key.identity_client_id

  dynamic "timeouts" {
    for_each = var.cognitive_account_customer_managed_key.timeouts == null ? [] : [
      var.cognitive_account_customer_managed_key.timeouts
    ]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azurerm_cognitive_deployment" "this" {
  for_each = var.cognitive_deployments

  cognitive_account_id   = azurerm_cognitive_account.this.id
  name                   = each.value.name
  rai_policy_name        = each.value.rai_policy_name
  version_upgrade_option = each.value.version_upgrade_option

  dynamic "model" {
    for_each = [each.value.model]
    content {
      format  = model.value.format
      name    = model.value.name
      version = model.value.version
    }
  }
  dynamic "scale" {
    for_each = [each.value.scale]
    content {
      type     = scale.value.type
      capacity = scale.value.capacity
      family   = scale.value.family
      size     = scale.value.size
      tier     = scale.value.tier
    }
  }
  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

