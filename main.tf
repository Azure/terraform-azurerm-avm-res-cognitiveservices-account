moved {
  from = random_string.default_custom_subdomain_name_suffix
  to   = random_string.default_custom_subdomain_name_suffix[0]
}

resource "random_string" "default_custom_subdomain_name_suffix" {
  count = var.kind != "AIServices" ? 1 : 0

  length  = 5
  special = false
  upper   = false
}

moved {
  from = azurerm_cognitive_account.this
  to   = azurerm_cognitive_account.this[0]
}

moved {
  from = azurerm_cognitive_account.this[0]
  to   = azapi_resource.this[0]
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

locals {
  sensitive_body_index   = local.sensitive_body_present ? 0 : 1
  sensitive_body_present = nonsensitive(anytrue([for item in local.sensitive_inputs : item != null]))
  sensitive_inputs = [
    var.custom_question_answering_search_service_key,
  ]
}

resource "azapi_resource" "this" {
  count = var.kind != "AIServices" ? 1 : 0

  location  = var.location
  name      = var.name
  parent_id = data.azurerm_resource_group.rg.id
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  body = { for k, v in {
    kind = var.kind
    sku = {
      name = var.sku_name
    }
    properties = { for k, v in {
      allowProjectManagement        = var.allow_project_management
      allowedFqdnList               = var.fqdns
      customSubDomainName           = coalesce(var.custom_subdomain_name, "azure-cognitive-${random_string.default_custom_subdomain_name_suffix[0].result}")
      disableLocalAuth              = try(!var.local_auth_enabled, false)
      dynamicThrottlingEnabled      = var.dynamic_throttling_enabled
      publicNetworkAccess           = var.public_network_access_enabled ? "Enabled" : "Disabled"
      restrictOutboundNetworkAccess = var.outbound_network_access_restricted == true
      apiProperties = { for k, v in {
        qnaRuntimeEndpoint       = var.kind == "QnAMaker" && var.qna_runtime_endpoint != null && var.qna_runtime_endpoint != "" ? var.qna_runtime_endpoint : null
        qnaAzureSearchEndpointId = var.kind == "TextAnalytics" && var.custom_question_answering_search_service_id != null ? var.custom_question_answering_search_service_id : null
        aadClientId              = var.metrics_advisor_aad_client_id != null && var.kind == "MetricsAdvisor" ? var.metrics_advisor_aad_client_id : null
        aadTenantId              = var.metrics_advisor_aad_tenant_id != null && var.kind == "MetricsAdvisor" ? var.metrics_advisor_aad_tenant_id : null
        superUser                = var.metrics_advisor_super_user_name != null && var.kind == "MetricsAdvisor" ? var.metrics_advisor_super_user_name : null
        websiteName              = var.metrics_advisor_website_name != null && var.kind == "MetricsAdvisor" ? var.metrics_advisor_website_name : null
        } : k => v if v != null
      }
      networkAcls = try({ for k, v in try({
        defaultAction = var.network_acls.default_action
        ipRules = try([for ip_rule in var.network_acls.ip_rules : {
          value = ip_rule
        }], null)
        virtualNetworkRules = try([for rule in var.network_acls.virtual_network_rules : {
          id                               = rule.subnet_id
          ignoreMissingVnetServiceEndpoint = rule.ignore_missing_vnet_service_endpoint == true
        }], null)
        bypass = var.kind == "OpenAI" ? var.network_acls.bypass : null
      }, null) : k => v if v != null }, null)
      userOwnedStorage = try([for storage in var.storage : {
        resourceId       = storage.storage_account_id
        identityClientId = storage.identity_client_id
      }], null)
    } : k => v if v != null }
  } : k => v if v != null }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  # This weird workaround is needed to avoid configuration drift, the Terraform conditional expression `condition ? true_val : false_val` would execute implicitly type conversion, which would cause the `null` value to be converted to an `null` value with object type.
  sensitive_body = [{
    properties = {
      apiProperties = {
        qnaAzureSearchEndpointKey = var.custom_question_answering_search_service_key != null && var.kind == "TextAnalytics" ? var.custom_question_answering_search_service_key : null
      }
    }
    },
    null,
  ][local.sensitive_body_index]
  tags           = var.tags
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "identity" {
    for_each = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? ["identity"] : []

    content {
      type         = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
      identity_ids = var.managed_identities.user_assigned_resource_ids
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
    precondition {
      condition     = var.network_acls == null ? true : (var.network_acls.bypass == null || var.network_acls.bypass == "" || var.kind == "OpenAI")
      error_message = "the `network_acls.bypass` does not support Trusted Services for the kind `${var.kind}`"
    }
  }
}

data "azapi_resource_action" "account_keys" {
  count = var.kind != "AIServices" ? 1 : 0

  action                           = "listKeys"
  resource_id                      = azapi_resource.this[0].id
  type                             = azapi_resource.this[0].type
  sensitive_response_export_values = ["*"]
}

locals {
  managed_key_identity_client_id = try(data.azurerm_user_assigned_identity.this[0].client_id, null)
}

data "azurerm_key_vault_key" "this" {
  count = var.customer_managed_key != null && !var.is_hsm_key ? 1 : 0

  key_vault_id = var.customer_managed_key.key_vault_resource_id
  name         = var.customer_managed_key.key_name
}

locals {
  hsm_id = var.customer_managed_key != null && var.is_hsm_key ? provider::azapi::parse_resource_id("Microsoft.KeyVault/managedHSMs", var.customer_managed_key.key_vault_resource_id) : null
}

data "azurerm_key_vault_managed_hardware_security_module" "this" {
  count = var.customer_managed_key != null && var.is_hsm_key ? 1 : 0

  name                = local.hsm_id.name
  resource_group_name = local.hsm_id.resource_group_name
}

data "azurerm_key_vault_managed_hardware_security_module_key" "this" {
  count = var.customer_managed_key != null && var.is_hsm_key ? 1 : 0

  managed_hsm_id = var.customer_managed_key.key_vault_resource_id
  name           = var.customer_managed_key.key_name
}

data "azurerm_user_assigned_identity" "this" {
  count = try(var.customer_managed_key.user_assigned_identity != null, false) ? 1 : 0

  #/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{userAssignedIdentityName}
  name                = reverse(split("/", var.customer_managed_key.user_assigned_identity.resource_id))[0]
  resource_group_name = split("/", var.customer_managed_key.user_assigned_identity.resource_id)[4]
}

resource "azurerm_cognitive_account_customer_managed_key" "this" {
  count = var.customer_managed_key != null && !var.is_hsm_key ? 1 : 0

  cognitive_account_id = local.resource_id
  key_vault_key_id     = data.azurerm_key_vault_key.this[0].id
  identity_client_id   = local.managed_key_identity_client_id

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

resource "azurerm_cognitive_deployment" "this" {
  for_each = var.cognitive_deployments

  cognitive_account_id       = local.resource_block.id
  name                       = each.value.name
  dynamic_throttling_enabled = each.value.dynamic_throttling_enabled
  rai_policy_name            = each.value.rai_policy_name
  version_upgrade_option     = each.value.version_upgrade_option

  dynamic "model" {
    for_each = [each.value.model]

    content {
      format  = model.value.format
      name    = model.value.name
      version = model.value.version
    }
  }
  dynamic "sku" {
    for_each = [each.value.scale]
    iterator = scale

    content {
      name     = scale.value.type
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

  depends_on = [
    azurerm_cognitive_account_customer_managed_key.this,
    azapi_resource.rai_policy,
  ]
}

locals {
  common_resource = {
    id                                 = local.resource_id
    name                               = try(azapi_resource.this[0].name, azapi_resource.ai_service[0].name)
    location                           = try(azapi_resource.this[0].location, azapi_resource.ai_service[0].location)
    resource_group_name                = var.resource_group_name
    sku_name                           = try(azapi_resource.this[0].body.sku.name, azapi_resource.ai_service[0].body.sku.name)
    custom_subdomain_name              = try(azapi_resource.this[0].body.properties.customSubDomainName, azapi_resource.ai_service[0].body.properties.customSubDomainName, null)
    customer_managed_key               = try(length(local.customer_managed_key) > 0 ? local.customer_managed_key : [], [])
    fqdns                              = try(length(local.fqdns) > 0 ? local.fqdns : null, null)
    identity                           = try(length(local.identity) > 0 ? local.identity : [], [])
    network_acls                       = try(length(local.network_acls) > 0 ? local.network_acls : [], [])
    outbound_network_access_restricted = try(azapi_resource.this[0].body.properties.restrictOutboundNetworkAccess, azapi_resource.ai_service[0].body.properties.restrictOutboundNetworkAccess)
    storage                            = try(length(local.storage) > 0 ? local.storage : [], [])
    tags                               = try(azapi_resource.this[0].tags, azapi_resource.ai_service[0].tags)
    endpoint                           = try(azapi_resource.this[0].output.properties.endpoint, azapi_resource.ai_service[0].output.properties.endpoint, null)
  }
  customer_managed_key = try({
    key_vault_key_id   = azurerm_cognitive_account_customer_managed_key.this[0].key_vault_key_id
    identity_client_id = azurerm_cognitive_account_customer_managed_key.this[0].identity_client_id
  }, {
    key_vault_key_id = data.azurerm_key_vault_managed_hardware_security_module_key.this[0].id
    identity_client_id = local.managed_key_identity_client_id
  }, null)
  fqdns = try(azapi_resource.this[0].body.properties.allowedFqdnList, azapi_resource.ai_service[0].body.properties.allowedFqdnList, [])
  identity = try([{
    type         = azapi_resource.this[0].identity[0].type
    identity_ids = azapi_resource.this[0].identity[0].identity_ids
    principal_id = azapi_resource.this[0].output.identity.principalId
    tenant_id    = azapi_resource.this[0].output.identity.tenantId
  }], [{
    type         = azapi_resource.ai_service[0].output.identity[0].type
    identity_ids = azapi_resource.ai_service[0].output.identity[0].identity_ids
    principal_id = azapi_resource.ai_service[0].output.identity.principalId
    tenant_id    = azapi_resource.ai_service[0].output.identity.tenantId
  }], null)
  network_acls = try({
    default_action = azapi_resource.this[0].body.properties.networkAcls.defaultAction
    ip_rules       = [for rule in azapi_resource.this[0].body.properties.networkAcls.ipRules : rule.value]
    virtual_network_rules = [for rule in azapi_resource.this[0].body.properties.networkAcls.virtualNetworkRules : {
      subnet_id                            = rule.id
      ignore_missing_vnet_service_endpoint = rule.ignoreMissingVnetServiceEndpoint
    }]
    bypass = azapi_resource.this[0].body.properties.networkAcls.bypass
  }, {
    default_action = azapi_resource.ai_service[0].body.properties.networkAcls.defaultAction
    ip_rules       = [for rule in azapi_resource.ai_service[0].body.properties.networkAcls.ipRules : rule.value]
    virtual_network_rules = [for rule in azapi_resource.ai_service[0].body.properties.networkAcls.virtualNetworkRules : {
      subnet_id                            = rule.id
      ignore_missing_vnet_service_endpoint = rule.ignoreMissingVnetServiceEndpoint
    }]
    bypass = azapi_resource.ai_service[0].body.properties.networkAcls.bypass
  }, null)
  resource_block = merge(local.common_resource, var.kind != "AIServices" ? {
    kind                                        = azapi_resource.this[0].body.kind
    dynamic_throttling_enabled                  = try(azapi_resource.this[0].body.properties.dynamicThrottlingEnabled, null)
    local_auth_enabled                          = try(!azapi_resource.this[0].body.properties.disableLocalAuth, null)
    metrics_advisor_aad_client_id               = try(azapi_resource.this[0].body.properties.apiProperties.aadClientId, null)
    metrics_advisor_aad_tenant_id               = try(azapi_resource.this[0].body.properties.apiProperties.aadTenantId, null)
    metrics_advisor_super_user_name             = try(azapi_resource.this[0].body.properties.apiProperties.superUser, null)
    metrics_advisor_website_name                = try(azapi_resource.this[0].body.properties.apiProperties.websiteName, null)
    public_network_access_enabled               = try(azapi_resource.this[0].body.properties.publicNetworkAccess == "Enabled" ? true : (azapi_resource.this[0].body.properties.publicNetworkAccess == "Disabled" ? false : null), null)
    qna_runtime_endpoint                        = try(azapi_resource.this[0].body.properties.apiProperties.qnaRuntimeEndpoint, null)
    custom_question_answering_search_service_id = try(azapi_resource.this[0].body.properties.apiProperties.qnaAzureSearchEndpointId, null)
    } : {
    local_authentication_enabled = try(!azapi_resource.ai_service[0].body.properties.disableLocalAuth, null)
    public_network_access        = try(azapi_resource.ai_service[0].body.properties.publicNetworkAccess == "Enabled" ? true : (azapi_resource.ai_service[0].body.properties.publicNetworkAccess == "Disabled" ? false : null), null)
  })
  resource_block_sensitive = var.kind != "AIServices" ? {
    custom_question_answering_search_service_key = sensitive(try(azapi_resource.this[0].body.properties.apiProperties.qnaAzureSearchEndpointKey, null))
    primary_access_key                           = sensitive(try(data.azapi_resource_action.account_keys[0].sensitive_output.key1, null))
    secondary_access_key                         = sensitive(try(data.azapi_resource_action.account_keys[0].sensitive_output.key2, null))
    } : {
    primary_access_key                           = sensitive(try(data.azapi_resource_action.ai_service_account_keys[0].sensitive_output.key1, null))
    secondary_access_key                         = sensitive(try(data.azapi_resource_action.ai_service_account_keys[0].sensitive_output.key2, null))
  }
  resource_id = try(azapi_resource.this[0].id, azapi_resource.ai_service[0].id)
  storage = try([for s in azapi_resource.this[0].body.properties.userOwnedStorage : {
    storage_account_id = s.resourceId
    identity_client_id = s.identityClientId
  }], [for s in azapi_resource.ai_service[0].body.properties.userOwnedStorage : {
    storage_account_id = s.resourceId
    identity_client_id = s.identityClientId
  }], null)
}
