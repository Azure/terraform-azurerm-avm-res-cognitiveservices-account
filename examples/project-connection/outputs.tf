output "resource_id" {
  description = "The ARM ID of the connection created by this example."
  value       = module.project_connection.resource_id
}

output "name" {
  description = "The connection name."
  value       = module.project_connection.name
}

output "model_references" {
  description = "Explicit agent model selections keyed by gateway deployment alias. These references do not prove inference readiness."
  value       = module.project_connection.model_references
}
