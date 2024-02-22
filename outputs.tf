output "name" {
  description = "The name of cognitive account created."
  value       = azurerm_cognitive_account.this.name
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = azurerm_private_endpoint.this
}

output "resource" {
  description = "The cognitive account resource created."
  value       = azurerm_cognitive_account.this
}

output "resource_cognitive_deployment" {
  description = "The map of cognitive deployments created."
  value       = azurerm_cognitive_deployment.this
}

output "resource_id" {
  description = "The resource ID of cognitive account created."
  value       = azurerm_cognitive_account.this.id
}

output "system_assigned_mi_principal_id" {
  description = "The principal ID of system assigned managed identity on the cognitive account created, when `var.managed_identities` is `null` or `var.managed_identities.system_assigned` is `false` this output is `null`."
  value       = try(var.managed_identities.system_assigned, false) ? azurerm_cognitive_account.this.identity[0].principal_id : null
}
