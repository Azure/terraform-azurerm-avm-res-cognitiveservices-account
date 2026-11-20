module "project_connection" {
  source   = "./modules/project-connection"
  for_each = var.project_connections

  audience            = each.value.audience
  models              = each.value.models
  name                = each.value.name
  parent_id           = "${local.resource_id}/projects/${each.value.project_name}"
  target              = each.value.target
  enable_telemetry    = var.enable_telemetry
  ignore_body_changes = var.ignore_body_changes.cognitiveservices_accounts_projects_connections
  location            = var.location
  resource_types      = var.resource_types.cognitiveservices_accounts_projects_connections
  retry               = var.retry
  timeouts            = var.timeouts
}
