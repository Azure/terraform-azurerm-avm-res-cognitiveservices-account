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
