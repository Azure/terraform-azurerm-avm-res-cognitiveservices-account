output "name" {
  description = "The name of the RAI policy."
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "The resource ID of the RAI policy."
  value       = azapi_resource.this.id
}

output "tags" {
  description = "The tags assigned to the RAI policy."
  value       = azapi_resource.this.tags
}
