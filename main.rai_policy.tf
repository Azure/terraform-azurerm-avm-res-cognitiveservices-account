# NOTE: no `moved` block migrating `azapi_resource.rai_policy` into `module.rai_policy`,
# for the same reason as `module.deployment` in main.tf - a `for_each`'d resource cannot be
# moved into a `for_each`'d module call. See the migration guide in the README.

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
  retry              = each.value.retry != null ? each.value.retry : var.retry
  timeouts           = each.value.timeouts != null ? each.value.timeouts : var.timeouts
}
