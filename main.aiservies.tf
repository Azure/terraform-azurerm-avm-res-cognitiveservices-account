moved {
  from = azurerm_ai_services.this
  to   = azapi_resource.ai_service
}

resource "azapi_resource" "ai_service" {
  count = var.kind == "AIServices" ? 1 : 0

  location  = var.location
  name      = var.name
  parent_id = data.azurerm_resource_group.rg.id
  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  body = { for k, v in {
    kind = "AIServices"
    sku = {
      name = var.sku_name
    }
    properties = merge(
      {
        raiMonitorConfig = var.rai_monitor_config != null ? {
          adxStorageResourceId = var.rai_monitor_config.adx_storage_resource_id
          identityClientId     = var.rai_monitor_config.identity_client_id
        } : null
      },
      { for k, v in {
        allowProjectManagement        = var.allow_project_management
        allowedFqdnList               = try(length(var.fqdns) > 0 ? var.fqdns : null, null)
        associatedProjects            = var.associated_projects
        customSubDomainName           = var.custom_subdomain_name
        defaultProject                = var.default_project
        disableLocalAuth              = try(!var.local_auth_enabled, false)
        dynamicThrottlingEnabled      = var.dynamic_throttling_enabled == false ? null : var.dynamic_throttling_enabled
        publicNetworkAccess           = var.public_network_access_enabled ? "Enabled" : "Disabled"
        restrictOutboundNetworkAccess = var.outbound_network_access_restricted == true
        networkAcls = try({ for k, v in try({
          defaultAction = var.network_acls.default_action
          ipRules = try([for ip_rule in var.network_acls.ip_rules : {
            value = ip_rule
          }], null)
          virtualNetworkRules = try([for rule in var.network_acls.virtual_network_rules : {
            id                               = rule.subnet_id
            ignoreMissingVnetServiceEndpoint = rule.ignore_missing_vnet_service_endpoint == true
          }], null)
        }, null) : k => v if v != null }, null)
        userOwnedStorage = try([for storage in var.storage : {
          resourceId       = storage.storage_account_id
          identityClientId = storage.identity_client_id
        }], null)
      } : k => v if v != null }
    )
  } : k => v if v != null }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
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
    ignore_changes = [
      body.properties.apiProperties,
      body.properties.apiProperties.qnaAzureSearchEndpointKey,
      body.properties.encryption
    ]

    precondition {
      condition     = var.network_acls == null ? true : (var.network_acls.bypass == null || var.network_acls.bypass == "")
      error_message = "the `network_acls.bypass` does not support Trusted Services for the kind `${var.kind}`"
    }
  }
}

locals {
  ai_service_encryption = var.is_hsm_key && var.customer_managed_key != null ? {
    keySource = "Microsoft.KeyVault"
    keyVaultProperties = {
      identityClientId = local.managed_key_identity_client_id
      keyName          = data.azurerm_key_vault_managed_hardware_security_module_key.this[0].name
      keyVaultUri      = data.azurerm_key_vault_managed_hardware_security_module.this[0].hsm_uri
      keyVersion       = data.azurerm_key_vault_managed_hardware_security_module_key.this[0].version
    }
    } : {
    keySource          = "Microsoft.CognitiveServices"
    keyVaultProperties = null
  }
}

resource "terraform_data" "ai_service_hsm_key_trigger" {
  count = var.kind == "AIServices" && var.is_hsm_key ? 1 : 0

  triggers_replace = {
    encryption = local.ai_service_encryption
  }
}

resource "time_sleep" "wait_ai_service_creation" {
  count = var.kind == "AIServices" ? 1 : 0

  create_duration = "10s"

  depends_on = [
    azapi_resource.ai_service
  ]
}

resource "azapi_update_resource" "ai_service_hsm_key" {
  count = var.kind == "AIServices" && var.is_hsm_key ? 1 : 0

  resource_id = azapi_resource.ai_service[0].id
  type        = "Microsoft.CognitiveServices/accounts@2025-06-01"
  body = {
    properties = {
      apiProperties = null
      encryption    = local.ai_service_encryption
    }
  }
  ignore_missing_property = true

  depends_on = [
    azapi_resource.ai_service,
    terraform_data.ai_service_hsm_key_trigger,
    time_sleep.wait_ai_service_creation,
  ]

  lifecycle {
    ignore_changes = all
    replace_triggered_by = [
      terraform_data.ai_service_hsm_key_trigger
    ]
  }
}

data "azapi_resource_action" "ai_service_account_keys" {
  count = var.kind == "AIServices" && try(var.local_auth_enabled, true) ? 1 : 0

  action                           = "listKeys"
  resource_id                      = azapi_resource.ai_service[0].id
  type                             = azapi_resource.ai_service[0].type
  sensitive_response_export_values = ["*"]

  depends_on = [
    azapi_update_resource.ai_service_hsm_key,
  ]
}
