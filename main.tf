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

resource "time_sleep" "wait_account_creation" {
  count = var.kind != "AIServices" ? 1 : 0

  create_duration = "10s"

  depends_on = [
    azapi_resource.this
  ]
}

data "azapi_resource_action" "account_keys" {
  count = var.kind != "AIServices" && try(var.local_auth_enabled, true) ? 1 : 0

  action                           = "listKeys"
  resource_id                      = azapi_resource.this[0].id
  type                             = azapi_resource.this[0].type
  sensitive_response_export_values = ["*"]

  depends_on = [
    time_sleep.wait_account_creation
  ]
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

moved {
  from = azurerm_cognitive_deployment.this
  to   = azapi_resource.cognitive_deployment
}

resource "azapi_resource" "cognitive_deployment" {
  for_each = var.cognitive_deployments

  name      = each.value.name
  parent_id = local.resource_id
  type      = "Microsoft.CognitiveServices/accounts/deployments@2025-06-01"
  body = {
    properties = { for k, v in {
      dynamicThrottlingEnabled = each.value.dynamic_throttling_enabled
      model = {
        format  = each.value.model.format
        name    = each.value.model.name
        version = each.value.model.version
      }
      raiPolicyName        = each.value.rai_policy_name
      versionUpgradeOption = each.value.version_upgrade_option
    } : k => v if v != null }
    sku = { for k, v in {
      name     = each.value.scale.type
      capacity = each.value.scale.capacity
      family   = each.value.scale.family
      size     = each.value.scale.size
      tier     = each.value.scale.tier
    } : k => v if v != null }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  # Add conditional locking to serialize deployment creation
  locks        = var.deployment_serialization_enabled ? [local.resource_id] : null
  read_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  # Add conditional retry logic to handle 409 conflicts when specified
  retry = each.value.retry != null ? {
    error_message_regex  = each.value.retry.error_message_regex
    interval_seconds     = each.value.retry.interval_seconds
    max_interval_seconds = each.value.retry.max_interval_seconds
    multiplier           = each.value.retry.multiplier
    randomization_factor = each.value.retry.randomization_factor
  } : null
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    azurerm_cognitive_account_customer_managed_key.this,
    azapi_resource.rai_policy,
  ]

  lifecycle {
    ignore_changes = [
      schema_validation_enabled,
    ]
  }
}

# for output resource body
locals {
  ai_service_custom_subdomain_name = try(azapi_resource.ai_service[0].body.properties.customSubDomainName == null ? "" : azapi_resource.ai_service[0].body.properties.customSubDomainName, "")
  common_resource = {
    id                                 = local.resource_id
    name                               = try(azapi_resource.this[0].name, azapi_resource.ai_service[0].name)
    location                           = try(azapi_resource.this[0].location, azapi_resource.ai_service[0].location)
    resource_group_name                = var.resource_group_name
    sku_name                           = try(azapi_resource.this[0].body.sku.name, azapi_resource.ai_service[0].body.sku.name)
    custom_subdomain_name              = try(azapi_resource.this[0].body.properties.customSubDomainName, local.ai_service_custom_subdomain_name, null)
    customer_managed_key               = try(length(local.customer_managed_key) > 0 ? local.customer_managed_key : [], [])
    fqdns                              = try(length(local.fqdns) > 0 ? local.fqdns : null, null)
    identity                           = try(length(local.identity) > 0 ? local.identity : [], [])
    network_acls                       = try(local.network_acls != null ? [local.network_acls] : [], [])
    outbound_network_access_restricted = try(azapi_resource.this[0].body.properties.restrictOutboundNetworkAccess, azapi_resource.ai_service[0].body.properties.restrictOutboundNetworkAccess)
    storage                            = try(length(local.storage) > 0 ? local.storage : [], [])
    tags                               = try(azapi_resource.this[0].tags, azapi_resource.ai_service[0].tags)
    endpoint                           = try(azapi_resource.this[0].output.properties.endpoint, azapi_resource.ai_service[0].output.properties.endpoint, null)
  }
  customer_managed_key = try([
    {
      key_vault_key_id   = azurerm_cognitive_account_customer_managed_key.this[0].key_vault_key_id
      identity_client_id = azurerm_cognitive_account_customer_managed_key.this[0].identity_client_id
    }], [
    {
      key_vault_key_id   = ""
      managed_hsm_key_id = data.azurerm_key_vault_managed_hardware_security_module_key.this[0].versioned_id
      identity_client_id = local.managed_key_identity_client_id
  }], null)
  fqdns = try(azapi_resource.this[0].body.properties.allowedFqdnList, azapi_resource.ai_service[0].body.properties.allowedFqdnList, [])
  identity = try([{
    type         = azapi_resource.this[0].identity[0].type
    identity_ids = azapi_resource.this[0].identity[0].identity_ids
    principal_id = azapi_resource.this[0].output.identity.principalId
    tenant_id    = azapi_resource.this[0].output.identity.tenantId
    }], [{
    type         = try(azapi_resource.ai_service[0].identity[0].type, null)
    identity_ids = try(azapi_resource.ai_service[0].identity[0].identity_ids, null)
    principal_id = try(azapi_resource.ai_service[0].identity[0].principal_id)
    tenant_id    = try(azapi_resource.ai_service[0].identity[0].tenant_id, null)
  }], null)
  ip_rules = try([for rule in azapi_resource.this[0].body.properties.networkAcls.ipRules : rule.value], [])
  network_acls = try({
    default_action = azapi_resource.this[0].body.properties.networkAcls.defaultAction
    ip_rules       = length(local.ip_rules) > 0 ? local.ip_rules : null
    virtual_network_rules = [for rule in azapi_resource.this[0].body.properties.networkAcls.virtualNetworkRules : {
      subnet_id                            = rule.id
      ignore_missing_vnet_service_endpoint = rule.ignoreMissingVnetServiceEndpoint
    }]
    bypass = try(azapi_resource.this[0].body.properties.networkAcls.bypass, "")
    }, {
    default_action = azapi_resource.ai_service[0].body.properties.networkAcls.defaultAction
    ip_rules       = [for rule in azapi_resource.ai_service[0].body.properties.networkAcls.ipRules : rule.value]
    virtual_network_rules = [for rule in azapi_resource.ai_service[0].body.properties.networkAcls.virtualNetworkRules : {
      subnet_id                            = rule.id
      ignore_missing_vnet_service_endpoint = rule.ignoreMissingVnetServiceEndpoint
    }]
    bypass = try(azapi_resource.ai_service[0].body.properties.networkAcls.bypass, "")
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
    public_network_access        = try(azapi_resource.ai_service[0].body.properties.publicNetworkAccess, "Enabled")
  })
  resource_block_sensitive = var.kind != "AIServices" ? {
    custom_question_answering_search_service_key = sensitive(try(azapi_resource.this[0].body.properties.apiProperties.qnaAzureSearchEndpointKey, null))
    primary_access_key                           = sensitive(try(data.azapi_resource_action.account_keys[0].sensitive_output.key1, null))
    secondary_access_key                         = sensitive(try(data.azapi_resource_action.account_keys[0].sensitive_output.key2, null))
    } : {
    primary_access_key   = sensitive(try(data.azapi_resource_action.ai_service_account_keys[0].sensitive_output.key1, null))
    secondary_access_key = sensitive(try(data.azapi_resource_action.ai_service_account_keys[0].sensitive_output.key2, null))
  }
  resource_cognitive_deployment = {
    for k, v in azapi_resource.cognitive_deployment : k => {
      id                         = v.id
      name                       = v.name
      cognitive_account_id       = v.parent_id
      dynamic_throttling_enabled = try(v.body.properties.dynamicThrottlingEnabled, false)
      model = [
        {
          format  = try(v.body.properties.model.format, null)
          name    = try(v.body.properties.model.name, null)
          version = try(v.body.properties.model.version, null)
      }]
      sku = [
        {
          name     = try(v.body.sku.name, "")
          capacity = try(v.body.sku.capacity, 1)
          family   = try(v.body.sku.family, "")
          size     = try(v.body.sku.size, "")
          tier     = try(v.body.sku.tier, "")
      }]
      rai_policy_name        = try(v.body.properties.raiPolicyName == null, true) ? "" : v.body.properties.raiPolicyName
      version_upgrade_option = v.body.properties.versionUpgradeOption
      timeouts = try({
        create = var.timeouts.create
        delete = var.timeouts.delete
        read   = var.timeouts.read
        update = var.timeouts.update
      }, null)
    }
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
