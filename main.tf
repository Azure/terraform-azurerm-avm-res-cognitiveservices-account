resource "random_string" "default_custom_subdomain_name_suffix" {
  length  = 5
  special = false
  upper   = false
}

locals {
  managed_key_identity_client_id = try(data.azurerm_user_assigned_identity.this[0].client_id, null)
}

data "azurerm_key_vault_key" "this" {
  count = var.customer_managed_key != null ? 1 : 0

  key_vault_id = var.customer_managed_key.key_vault_resource_id
  name         = var.customer_managed_key.key_name
}

data "azurerm_user_assigned_identity" "this" {
  count = try(var.customer_managed_key.user_assigned_identity != null, false) ? 1 : 0

  name                = reverse(split("/", var.customer_managed_key.user_assigned_identity.resource_id))[0]
  resource_group_name = split("/", var.customer_managed_key.user_assigned_identity.resource_id)[4]
}

resource "azurerm_cognitive_account_customer_managed_key" "this" {
  count = var.customer_managed_key != null ? 1 : 0

  cognitive_account_id = azurerm_cognitive_account.cognitive_account.id
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

module "deployment" {
  source   = "./modules/deployment"
  for_each = var.cognitive_deployments

  model                      = each.value.model
  name                       = each.value.name
  cognitive_account_id       = azurerm_cognitive_account.cognitive_account.id
  scale                      = each.value.scale
  dynamic_throttling_enabled = each.value.dynamic_throttling_enabled
  rai_policy_name            = each.value.rai_policy_name
  timeouts               = each.value.timeouts != null ? each.value.timeouts : var.timeouts
  version_upgrade_option = each.value.version_upgrade_option

  depends_on = [
    azurerm_cognitive_account_customer_managed_key.this,
    module.rai_policy,
  ]
}

# # for output resource body
locals {
  cognitive_account_custom_subdomain_name = try(azurerm_cognitive_account.cognitive_account.custom_subdomain_name == null ? "" : azurerm_cognitive_account.cognitive_account.custom_subdomain_name, "")
  common_resource = {
    id                                 = local.resource_id
    name                               = try(azurerm_cognitive_account.cognitive_account.name, null)
    location                           = try(azurerm_cognitive_account.cognitive_account.location, null)
    resource_group_name                = var.resource_group_name
    sku_name                           = try(azurerm_cognitive_account.cognitive_account.sku_name, null)
    custom_subdomain_name              = try(local.cognitive_account_custom_subdomain_name, null)
    customer_managed_key               = try(length(local.customer_managed_key) > 0 ? local.customer_managed_key : [], [])
    fqdns                              = try(length(local.fqdns) > 0 ? local.fqdns : null, null)
    identity                           = try(length(local.identity) > 0 ? local.identity : [], [])
    network_acls                       = try(local.network_acls != null ? [local.network_acls] : [], [])
    outbound_network_access_restricted = try(azurerm_cognitive_account.cognitive_account.outbound_network_access_restricted, null)
    storage                            = try(length(local.storage) > 0 ? local.storage : [], [])
    tags                               = try(azurerm_cognitive_account.cognitive_account.tags)
    endpoint                           = try(azurerm_cognitive_account.cognitive_account.endpoint, null)
  }
  customer_managed_key = try([
    {
      key_vault_key_id   = azurerm_cognitive_account_customer_managed_key.this[0].key_vault_key_id
      identity_client_id = azurerm_cognitive_account_customer_managed_key.this[0].identity_client_id
    }], [
    {
      key_vault_key_id   = ""
      identity_client_id = local.managed_key_identity_client_id
  }], null)
  fqdns = try(azurerm_cognitive_account.cognitive_account.fqdns, [])
  identity = try([{
    type         = try(azurerm_cognitive_account.cognitive_account.identity[0].type, null)
    identity_ids = try(azurerm_cognitive_account.cognitive_account.identity[0].identity_ids, null)
    principal_id = try(azurerm_cognitive_account.cognitive_account.identity[0].principal_id)
    tenant_id    = try(azurerm_cognitive_account.cognitive_account.identity[0].tenant_id, null)
  }], null)
  ip_rules = try([for rule in azurerm_cognitive_account.cognitive_account.network_acls[0].ip_rules : rule.value], [])
  network_acls = try({
    default_action = azurerm_cognitive_account.cognitive_account.network_acls[0].default_action
    ip_rules       = length(local.ip_rules) > 0 ? local.ip_rules : null
    virtual_network_rules = [for rule in azurerm_cognitive_account.cognitive_account.network_acls[0].virtual_network_rules : {
      subnet_id                            = rule.id
      ignore_missing_vnet_service_endpoint = rule.ignore_missing_vnet_service_endpoint
    }]
    bypass = try(azurerm_cognitive_account.cognitive_account.network_acls[0].bypass, "")
    }, null)
  resource_block = merge(local.common_resource, {
    kind                                        = azurerm_cognitive_account.cognitive_account.kind
    dynamic_throttling_enabled                  = try(azurerm_cognitive_account.cognitive_account.dynamic_throttling_enabled, null)
    local_auth_enabled                          = try(!azurerm_cognitive_account.cognitive_account.local_auth_enabled, null)
    metrics_advisor_aad_client_id               = try(azurerm_cognitive_account.cognitive_account.metrics_advisor_aad_client_id, null)
    metrics_advisor_aad_tenant_id               = try(azurerm_cognitive_account.cognitive_account.metrics_advisor_aad_tenant_id, null)
    metrics_advisor_super_user_name             = try(azurerm_cognitive_account.cognitive_account.metrics_advisor_super_user_name, null)
    metrics_advisor_website_name                = try(azurerm_cognitive_account.cognitive_account.metrics_advisor_website_name, null)
    public_network_access_enabled               = try(azurerm_cognitive_account.cognitive_account.public_network_access_enabled, null)
    qna_runtime_endpoint                        = try(azurerm_cognitive_account.cognitive_account.qna_runtime_endpoint, null)
    custom_question_answering_search_service_id = try(azurerm_cognitive_account.cognitive_account.custom_question_answering_search_service_id, null)
    })
  resource_block_sensitive = {
    primary_access_key   = sensitive(try(azurerm_cognitive_account.cognitive_account.primary_access_key, null))
    secondary_access_key = sensitive(try(azurerm_cognitive_account.cognitive_account.secondary_access_key, null))
  }
  resource_cognitive_deployment = { for k, v in module.deployment : k => v.resource }
  resource_id                   = try(azurerm_cognitive_account.cognitive_account.id, "")
  storage = try([for s in azurerm_cognitive_account.cognitive_account.storage : {
    storage_account_id = s.storage_account_id
    identity_client_id = s.identity_client_id
  }], null)
}
