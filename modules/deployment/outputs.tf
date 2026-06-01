output "name" {
  description = "The name of the Cognitive Services deployment."
  value       = azapi_resource.this.name
}

output "resource" {
  description = "The deployment resource shaped to match the AzureRM cognitive deployment schema."
  value = {
    id                         = azapi_resource.this.id
    name                       = azapi_resource.this.name
    cognitive_account_id       = azapi_resource.this.parent_id
    dynamic_throttling_enabled = try(azapi_resource.this.body.properties.dynamicThrottlingEnabled, false)
    model = [
      {
        format  = try(azapi_resource.this.body.properties.model.format, null)
        name    = try(azapi_resource.this.body.properties.model.name, null)
        version = try(azapi_resource.this.body.properties.model.version, null)
      }
    ]
    sku = [
      {
        name     = try(azapi_resource.this.body.sku.name, "")
        capacity = try(azapi_resource.this.body.sku.capacity, 1)
        family   = try(azapi_resource.this.body.sku.family, "")
        size     = try(azapi_resource.this.body.sku.size, "")
        tier     = try(azapi_resource.this.body.sku.tier, "")
      }
    ]
    rai_policy_name        = try(azapi_resource.this.body.properties.raiPolicyName == null, true) ? "" : azapi_resource.this.body.properties.raiPolicyName
    version_upgrade_option = azapi_resource.this.body.properties.versionUpgradeOption
    timeouts = var.timeouts == null ? null : {
      create = var.timeouts.create
      delete = var.timeouts.delete
      read   = var.timeouts.read
      update = var.timeouts.update
    }
  }
}

output "resource_id" {
  description = "The resource ID of the Cognitive Services deployment."
  value       = azapi_resource.this.id
}
