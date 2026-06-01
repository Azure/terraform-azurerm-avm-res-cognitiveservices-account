resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.CognitiveServices/accounts/deployments@2025-06-01"
  body = {
    properties = { for k, v in {
      dynamicThrottlingEnabled = var.dynamic_throttling_enabled
      model = {
        format  = var.model.format
        name    = var.model.name
        version = var.model.version
      }
      raiPolicyName        = var.rai_policy_name
      versionUpgradeOption = var.version_upgrade_option
    } : k => v if v != null }
    sku = { for k, v in {
      name     = var.scale.type
      capacity = var.scale.capacity
      family   = var.scale.family
      size     = var.scale.size
      tier     = var.scale.tier
    } : k => v if v != null }
  }
  create_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  locks                     = var.lock_id != null ? [var.lock_id] : null
  read_headers              = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  retry                     = var.retry
  schema_validation_enabled = false
  update_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

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
    ignore_changes = [
      schema_validation_enabled,
    ]
  }
}
