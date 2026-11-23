resource "azapi_resource" "this" {
  name                   = var.name
  parent_id              = var.parent_id
  type                   = var.resource_types.cognitiveservices_accounts_projects_connections
  body                   = local.connection_bodies[var.category]
  ignore_body_changes    = length(var.ignore_body_changes.cognitiveservices_accounts_projects_connections) > 0 ? var.ignore_body_changes.cognitiveservices_accounts_projects_connections : null
  response_export_values = []
  retry                  = var.retry
  # Validate only combinations represented by the published ARM schema.
  schema_validation_enabled = contains(local.standard_categories, var.category) && var.auth_type != "ProjectManagedIdentity"
  sensitive_body            = local.sensitive_bodies[var.auth_type]
  sensitive_body_version = contains(["AAD", "None", "ProjectManagedIdentity"], var.auth_type) ? null : {
    "properties.credentials" = "${var.auth_type}:${var.credentials_version}"
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
