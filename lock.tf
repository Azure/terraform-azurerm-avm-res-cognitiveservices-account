resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.lock.kind}")
  parent_id = local.resource_id
  type      = "Microsoft.Authorization/locks@2020-05-01"
  body = {
    properties = {
      level = var.lock.kind
      notes = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
    }
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  # Create the lock last and remove it first. A ReadOnly lock blocks changes to the child resources.
  depends_on = [time_sleep.lock_removal]
}

# Azure keeps enforcing a deleted lock for a few seconds, and the AzureRM provider waited for the lock
# to be gone before it continued. This pause does the same: it is destroyed after the lock and before
# the account and the resources under it.
resource "time_sleep" "lock_removal" {
  count = var.lock != null ? 1 : 0

  destroy_duration = "30s"

  depends_on = [
    azapi_resource.ai_service,
    azapi_resource.diagnostic_settings,
    azapi_resource.private_dns_zone_groups,
    azapi_resource.private_endpoints,
    azapi_resource.private_endpoints_unmanaged,
    azapi_resource.role_assignments,
    azapi_resource.this,
    module.deployment,
    module.rai_policy,
  ]
}

moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.lock
}
