# Upgrades from root-level policies require consumer-declared per-key moves.

module "rai_policy" {
  source   = "./modules/rai_policy"
  for_each = var.rai_policies

  base_policy_name   = each.value.base_policy_name
  mode               = each.value.mode
  name               = each.value.name
  parent_id          = local.resource_id
  content_filters    = each.value.content_filters
  custom_block_lists = each.value.custom_block_lists
  enable_telemetry   = var.enable_telemetry
  location           = var.location
  retry              = each.value.retry != null ? each.value.retry : var.retry
  tags               = each.value.tags
  timeouts           = each.value.timeouts != null ? each.value.timeouts : var.timeouts
}
