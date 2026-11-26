output "model_references" {
  description = "Agent model references keyed by gateway deployment name. Selection is explicit; existence does not establish inference readiness."
  value       = { for deployment_name, model in var.models : deployment_name => "${azapi_resource.this.name}/${deployment_name}" }
}

output "name" {
  description = "Name of the project-scoped connection."
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "ARM resource ID of the project-scoped connection."
  value       = azapi_resource.this.id
}
