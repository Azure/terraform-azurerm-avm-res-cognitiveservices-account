resource "azurerm_cognitive_account" "cognitive_account" {
  name = var.name
  kind = var.kind
  resource_group_name = var.resource_group_name
  location = var.location
  sku_name = var.sku_name
  custom_subdomain_name = coalesce(var.custom_subdomain_name, "azure-cognitive-${random_string.default_custom_subdomain_name_suffix.result}")
  fqdns = try(length(var.fqdns) > 0 ? var.fqdns : null, null)
  qna_runtime_endpoint       = var.kind == "QnAMaker" && var.qna_runtime_endpoint != null && var.qna_runtime_endpoint != "" ? var.qna_runtime_endpoint : null
  custom_question_answering_search_service_id = var.kind == "TextAnalytics" && var.custom_question_answering_search_service_id != null ? var.custom_question_answering_search_service_id : null
  metrics_advisor_aad_client_id              = var.metrics_advisor_aad_client_id != null && var.kind == "MetricsAdvisor" ? var.metrics_advisor_aad_client_id : null
  metrics_advisor_aad_tenant_id              = var.metrics_advisor_aad_tenant_id != null && var.kind == "MetricsAdvisor" ? var.metrics_advisor_aad_tenant_id : null
  metrics_advisor_super_user_name                = var.metrics_advisor_super_user_name != null && var.kind == "MetricsAdvisor" ? var.metrics_advisor_super_user_name : null
  metrics_advisor_website_name              = var.metrics_advisor_website_name != null && var.kind == "MetricsAdvisor" ? var.metrics_advisor_website_name : null
  dynamic "customer_managed_key" {
    for_each = data.azurerm_key_vault_key.this
    content {
      key_vault_key_id = data.azurerm_key_vault_key.this[0].id
      identity_client_id = data.azurerm_user_assigned_identity.this[0].client_id 
    }
  }

  dynamic "identity" {
    for_each = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? ["identity"] : []
    content {
      type         = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
      identity_ids = var.managed_identities.user_assigned_resource_ids
    }
  }

  network_acls {
    bypass = try(var.network_acls.bypass, null)
    default_action = try(var.network_acls.default_action, null)
    ip_rules = try([for ip_rule in var.network_acls.ip_rules : {value = ip_rule}], null)
    dynamic "virtual_network_rules" {
      for_each = try(var.network_acls.virtual_network_rules == null ? [] : var.network_acls.virtual_network_rules, [])
      content {
        subnet_id = try(virtual_network_rules.value.subnet_id, null)
        ignore_missing_vnet_service_endpoint = try(virtual_network_rules.value.ignore_missing_vnet_service_endpoint, null)
      }
    }
  }

  local_auth_enabled = try(!var.local_auth_enabled, false)
  outbound_network_access_restricted = var.outbound_network_access_restricted == true
  public_network_access_enabled = try(var.public_network_access_enabled, false)
  
  dynamic "storage" {
    for_each = try(var.storage == null ? {} : var.storage, {})
    content {
      storage_account_id = storage.storage_account_id
      identity_client_id = storage.identity_client_id
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

  lifecycle {
    precondition {
      condition     = var.kind != "QnAMaker" || (var.qna_runtime_endpoint != null && var.qna_runtime_endpoint != "")
      error_message = "the QnAMaker runtime endpoint `qna_runtime_endpoint` is required when kind is set to `QnAMaker`"
    }
    precondition {
      condition     = var.custom_question_answering_search_service_id == null || var.kind == "TextAnalytics"
      error_message = "the Search Service ID `custom_question_answering_search_service_id` can only be set when kind is set to `TextAnalytics`"
    }
    precondition {
      condition     = var.custom_question_answering_search_service_key == null || var.kind == "TextAnalytics"
      error_message = "the Search Service Key `custom_question_answering_search_service_key` can only be set when kind is set to `TextAnalytics`"
    }
    precondition {
      condition     = var.metrics_advisor_aad_client_id == null || var.kind == "MetricsAdvisor"
      error_message = "metrics_advisor_aad_client_id can only used set when kind is set to `MetricsAdvisor`"
    }
    precondition {
      condition     = var.metrics_advisor_aad_tenant_id == null || var.kind == "MetricsAdvisor"
      error_message = "metrics_advisor_aad_tenant_id can only used set when kind is set to `MetricsAdvisor`"
    }
    precondition {
      condition     = var.metrics_advisor_super_user_name == null || var.kind == "MetricsAdvisor"
      error_message = "metrics_advisor_super_user_name can only used set when kind is set to `MetricsAdvisor`"
    }
    precondition {
      condition     = var.metrics_advisor_website_name == null || var.kind == "MetricsAdvisor"
      error_message = "metrics_advisor_website_name can only used set when kind is set to `MetricsAdvisor`"
    }
  }
}