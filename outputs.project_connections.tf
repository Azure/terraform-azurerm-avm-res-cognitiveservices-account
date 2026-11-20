output "project_connection_model_references" {
  description = "Model references keyed first by project_connections input key, then by gateway deployment alias. These references do not establish inference readiness."
  value       = { for key, connection in module.project_connection : key => connection.model_references }
}

output "project_connection_resource_ids" {
  description = "Project connection ARM IDs keyed by project_connections input keys."
  value       = { for key, connection in module.project_connection : key => connection.resource_id }
}
