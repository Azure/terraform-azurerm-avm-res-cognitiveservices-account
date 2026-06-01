resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01"
  body = {
    properties = {
      basePolicyName = var.base_policy_name
      mode           = var.mode
      contentFilters = try([for c in var.content_filters : {
        blocking          = c.blocking
        enabled           = c.enabled
        name              = c.name
        severityThreshold = c.severity_threshold
        source            = c.source
      }], null)
      customBlocklists = try([for c in var.custom_block_lists : {
        source        = c.source
        blocklistName = c.block_list_name
        blocking      = c.blocking
      }], null)
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  retry          = var.retry
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

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
