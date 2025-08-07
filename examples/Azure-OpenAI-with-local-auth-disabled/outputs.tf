output "aiservices_resource_id" {
  description = "The ID of the created AIServices cognitive service account"
  value       = module.test_aiservices.resource_id
}

# Resource IDs for reference
output "openai_resource_id" {
  description = "The ID of the created OpenAI cognitive service account"
  value       = module.test_openai.resource_id
}
