output "name" {
  description = "The name of the Cognitive Services deployment."
  value       = var.name
}

output "resource" {
  description = "The deployment resource shaped to match the AzureRM cognitive deployment schema."
  value = {
    id                         = azurerm_cognitive_deployment.this.id
    name                       = var.name
    cognitive_account_id       = var.cognitive_account_id
    dynamic_throttling_enabled = try(var.dynamic_throttling_enabled, false)
    model = [
      {
        format  = try(var.model.format, null)
        name    = try(var.model.name, null)
        version = try(var.model.version, null)
      }
    ]
    sku = [
      {
        name     = try(var.scale.name, "")
        capacity = try(var.scale.capacity, 1)
        family   = try(var.scale.family, "")
        size     = try(var.scale.size, "")
        tier     = try(var.scale.tier, "")
      }
    ]
    rai_policy_name        = var.rai_policy_name
    version_upgrade_option = var.version_upgrade_option
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
  value       = azurerm_cognitive_deployment.this.id
}
