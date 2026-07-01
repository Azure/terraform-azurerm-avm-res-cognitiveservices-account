output "name" {
  description = "The name of the RAI policy."
  value       = var.name
}

output "resource_id" {
  description = "The resource ID of the RAI policy."
  value       = azurerm_cognitive_account_rai_policy.this.id
}
