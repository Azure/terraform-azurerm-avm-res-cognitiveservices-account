module "project_connection" {
  source = "../../modules/project-connection"

  audience         = local.audience
  models           = var.models
  name             = var.name
  parent_id        = local.parent_id
  target           = local.target
  enable_telemetry = var.enable_telemetry
  location         = var.location

  depends_on = [
    azapi_resource.gateway_policy,
    azapi_resource.chat_completions,
    azapi_resource.model,
  ]
}
