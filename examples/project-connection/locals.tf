locals {
  create_fixture = var.parent_id == null && var.target == null && var.audience == null
  audience       = local.create_fixture ? "https://cognitiveservices.azure.com" : var.audience
  parent_id      = local.create_fixture ? azapi_resource.project[0].id : var.parent_id
  target         = local.create_fixture ? "${trimsuffix(azapi_resource.gateway[0].output.properties.gatewayUrl, "/")}/ai/v1" : var.target
}
