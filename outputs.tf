output "endpoint" {
  description = "The endpoint used to connect to the Cognitive Service Account."
  value       = var.kind != "AIServices" ? azurerm_cognitive_account.this[0].endpoint : azurerm_ai_services.this[0].endpoint
}

output "name" {
  description = "The name of cognitive account created."
  value       = var.kind != "AIServices" ? azurerm_cognitive_account.this[0].name : azurerm_ai_services.this[0].name
}

output "primary_access_key" {
  description = "A primary access key which can be used to connect to the Cognitive Service Account."
  sensitive   = true
  value       = var.kind != "AIServices" ? azurerm_cognitive_account.this[0].primary_access_key : azurerm_ai_services.this[0].primary_access_key
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = azurerm_private_endpoint.this
}

output "rai_policy_id" {
  description = "The ID of the RAI policy created."
  value       = { for k, v in azapi_resource.rai_policy : k => v.id }
}

output "resource" {
  description = "The cognitive account resource created."
  value       = var.kind != "AIServices" ? azurerm_cognitive_account.this[0] : azurerm_ai_services.this[0]
}

output "resource_cognitive_deployment" {
  description = "The map of cognitive deployments created."
  value       = azurerm_cognitive_deployment.this
}

output "resource_id" {
  description = "The resource ID of cognitive account created."
  value       = var.kind != "AIServices" ? azurerm_cognitive_account.this[0].id : azurerm_ai_services.this[0].id
}

output "secondary_access_key" {
  description = "A secondary access key which can be used to connect to the Cognitive Service Account."
  sensitive   = true
  value       = var.kind != "AIServices" ? azurerm_cognitive_account.this[0].secondary_access_key : azurerm_ai_services.this[0].secondary_access_key
}

output "system_assigned_mi_principal_id" {
  description = "The principal ID of system assigned managed identity on the Cognitive/AI Service account created, when `var.managed_identities` is `null` or `var.managed_identities.system_assigned` is `false` this output is `null`."
  value       = try(var.managed_identities.system_assigned, false) ? (var.kind != "AIServices" ? azurerm_cognitive_account.this[0].identity[0].principal_id : azurerm_ai_services.this[0].identity[0].principal_id) : null
}
