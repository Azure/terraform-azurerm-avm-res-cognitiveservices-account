resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.cognitiveservices_accounts_projects_connections
  body = {
    properties = {
      category      = "ApiManagement"
      authType      = "ProjectManagedIdentity"
      audience      = var.audience
      target        = var.target
      isSharedToAll = false
      credentials   = {}
      metadata = {
        deploymentInPath = "false"
        models = jsonencode([
          for deployment_name, model in var.models : {
            name = deployment_name
            properties = {
              model = {
                name    = model.model_name
                version = model.model_version
                format  = "OpenAI"
              }
            }
          }
        ])
      }
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.cognitiveservices_accounts_projects_connections) > 0 ? var.ignore_body_changes.cognitiveservices_accounts_projects_connections : null
  response_export_values = []
  retry                  = var.retry
  # Microsoft's APIM sample uses preview discriminators absent from the published ARM schema.
  schema_validation_enabled = false

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
