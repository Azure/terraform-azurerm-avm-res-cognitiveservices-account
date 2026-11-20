module "project_connection" {
  source   = "./modules/project-connection"
  for_each = var.project_connections

  name                = each.value.name
  parent_id           = "${local.resource_id}/projects/${each.value.project_name}"
  target              = each.value.target
  audience            = each.value.audience
  auth_type           = each.value.auth_type
  category            = each.value.category
  credentials         = lookup(var.project_connection_credentials, each.key, {})
  credentials_version = each.value.credentials_version
  enable_telemetry    = var.enable_telemetry
  ignore_body_changes = var.ignore_body_changes.cognitiveservices_accounts_projects_connections
  is_shared_to_all    = each.value.is_shared_to_all
  location            = var.location
  metadata            = each.value.metadata
  models              = each.value.models
  resource_types      = var.resource_types.cognitiveservices_accounts_projects_connections
  retry               = var.retry
  timeouts            = var.timeouts
}
