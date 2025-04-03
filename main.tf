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

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azapi_resource" "account" {
  count = var.kind != "AIServices" ? 1 : 0

  type      = "Microsoft.CognitiveServices/accounts@2024-10-01"
  location  = var.location
  name      = var.name
  parent_id = data.azurerm_resource_group.rg.id
  tags      = var.tags
  body = {
    kind = var.kind
    identity = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? {
      type                   = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
      userAssignedIdentities = var.managed_identities.user_assigned_resource_ids
    } : null
    properties = {
      allowedFqdnList               = var.fqdns
      customSubDomainName           = coalesce(var.custom_subdomain_name, "azure-cognitive-${random_string.default_custom_subdomain_name_suffix[0].result}")
      disableLocalAuth              = try(!var.local_auth_enabled, false)
      dynamicThrottlingEnabled      = var.dynamic_throttling_enabled
      publicNetworkAccess           = var.public_network_access_enabled ? "Enabled" : "Disabled"
      restrictOutboundNetworkAccess = var.outbound_network_access_restricted == true
      sku = {
        name = var.sku_name
      }
      apiProperties = {
        qnaRuntimeEndpoint        = var.kind == "QnAMaker" && var.qna_runtime_endpoint != null && var.qna_runtime_endpoint != "" ? var.qna_runtime_endpoint : null
        qnaAzureSearchEndpointId  = var.kind == "TextAnalytics" && var.custom_question_answering_search_service_id != null ? var.custom_question_answering_search_service_id : null
        qnaAzureSearchEndpointKey = var.custom_question_answering_search_service_key != null && var.kind == "TextAnalytics" ? var.custom_question_answering_search_service_key : null
        aadClientId               = var.metrics_advisor_aad_client_id != null && var.kind == "MetricsAdvisor" ? var.metrics_advisor_aad_client_id : null
        aadTenantId               = var.metrics_advisor_aad_tenant_id != null && var.kind == "MetricsAdvisor" ? var.metrics_advisor_aad_tenant_id : null
        superUser                 = var.metrics_advisor_super_user_name != null && var.kind == "MetricsAdvisor" ? var.metrics_advisor_super_user_name : null
        websiteName               = var.metrics_advisor_website_name != null && var.kind == "MetricsAdvisor" ? var.metrics_advisor_website_name : null
      }
      networkAcls = try({
        defaultAction = var.network_acls.default_action
        ipRules = try([for ip_rule in var.network_acls.ip_rules : {
          value = ip_rule
        }], null)
        virtualNetworkRules = try([for rule in var.network_acls.virtual_network_rules : {
          id                               = rule.subnet_id
          ignoreMissingVnetServiceEndpoint = var.network_acls.ignore_missing_vnet_service_endpoint == true
        }], null)
        bypass = var.kind == "OpenAI" ? var.network_acls.bypass : null
      }, null)
      userOwnedStorage = try([for storage in var.storage : {
        resourceId       = storage.storage_account_id
        identityClientId = storage.identity_client_id
      }], null)
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

# resource "azurerm_cognitive_account" "this" {
#   count = var.kind != "AIServices" ? 1 : 0
#
#   kind                                         = var.kind
#   location                                     = var.location
#   name                                         = var.name
#   resource_group_name                          = var.resource_group_name
#   sku_name                                     = var.sku_name
#   custom_question_answering_search_service_id  = var.custom_question_answering_search_service_id
#   custom_question_answering_search_service_key = var.custom_question_answering_search_service_key
#   custom_subdomain_name                        = coalesce(var.custom_subdomain_name, "azure-cognitive-${random_string.default_custom_subdomain_name_suffix[0].result}")
#   dynamic_throttling_enabled                   = var.dynamic_throttling_enabled
#   fqdns                                        = var.fqdns
#   local_auth_enabled                           = var.local_auth_enabled
#   metrics_advisor_aad_client_id                = var.metrics_advisor_aad_client_id
#   metrics_advisor_aad_tenant_id                = var.metrics_advisor_aad_tenant_id
#   metrics_advisor_super_user_name              = var.metrics_advisor_super_user_name
#   metrics_advisor_website_name                 = var.metrics_advisor_website_name
#   outbound_network_access_restricted           = var.outbound_network_access_restricted
#   public_network_access_enabled                = var.public_network_access_enabled
#   qna_runtime_endpoint                         = var.qna_runtime_endpoint
#   tags                                         = var.tags
#
#   dynamic "identity" {
#     for_each = (var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0) ? { this = var.managed_identities } : {}
#
#     content {
#       type         = identity.value.system_assigned && length(identity.value.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(identity.value.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
#       identity_ids = identity.value.user_assigned_resource_ids
#     }
#   }
#   dynamic "network_acls" {
#     for_each = var.network_acls == null ? [] : [var.network_acls]
#
#     content {
#       default_action = network_acls.value.default_action
#       bypass         = network_acls.value.bypass
#       ip_rules       = network_acls.value.ip_rules
#
#       dynamic "virtual_network_rules" {
#         for_each = network_acls.value.virtual_network_rules == null ? [] : network_acls.value.virtual_network_rules
#
#         content {
#           subnet_id                            = virtual_network_rules.value.subnet_id
#           ignore_missing_vnet_service_endpoint = virtual_network_rules.value.ignore_missing_vnet_service_endpoint
#         }
#       }
#     }
#   }
#   dynamic "storage" {
#     for_each = var.storage == null ? [] : var.storage
#
#     content {
#       storage_account_id = storage.value.storage_account_id
#       identity_client_id = storage.value.identity_client_id
#     }
#   }
#   dynamic "timeouts" {
#     for_each = var.timeouts == null ? [] : [var.timeouts]
#
#     content {
#       create = timeouts.value.create
#       delete = timeouts.value.delete
#       read   = timeouts.value.read
#       update = timeouts.value.update
#     }
#   }
#
#   lifecycle {
#     ignore_changes = [
#       customer_managed_key,
#     ]
#
#     precondition {
#       # we cannot add this check on `azurerm_cognitive_account_customer_managed_key` resource, since when `var.is_hsm_key` is `false` the resource won't be created.
#       condition     = var.kind == "AIServices" || !var.is_hsm_key
#       error_message = "HSM key could only be used when `var.kind == \"AIServices\"`"
#     }
#   }
# }

locals {
  managed_key_identity_client_id = try(data.azurerm_user_assigned_identity.this[0].client_id, null)
}

data "azurerm_key_vault_key" "this" {
  count = var.customer_managed_key != null && !var.is_hsm_key ? 1 : 0

  key_vault_id = var.customer_managed_key.key_vault_resource_id
  name         = var.customer_managed_key.key_name
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

  cognitive_account_id = local.resource_block.id
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
    azurerm_cognitive_account_customer_managed_key.this
  ]
}

locals {
  # resource_block = try(azurerm_cognitive_account.this[0], azurerm_ai_services.this[0])
  resource_block = try(azapi_resource.account[0], azurerm_ai_services.this[0])
}
