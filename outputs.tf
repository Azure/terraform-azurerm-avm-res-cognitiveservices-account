output "name" {
  value = azurerm_cognitive_account.this.name
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = azurerm_private_endpoint.this
}

output "resource" {
  value = azurerm_cognitive_account.this
}

output "resource_cognitive_deployment" {
  value = azurerm_cognitive_deployment.this
}

output "resource_id" {
  value = azurerm_cognitive_account.this.id
}

output "system_assigned_mi_principal_id" {
  value = try(var.managed_identities.system_assigned, false) ? azurerm_cognitive_account.this.identity[0].principal_id : null
}
