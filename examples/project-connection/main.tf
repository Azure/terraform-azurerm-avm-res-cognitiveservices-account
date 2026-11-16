module "project_connection" {
  source = "../../modules/project-connection"

  audience         = var.audience
  models           = var.models
  name             = var.name
  parent_id        = var.parent_id
  target           = var.target
  enable_telemetry = var.enable_telemetry
  location         = var.location
}
