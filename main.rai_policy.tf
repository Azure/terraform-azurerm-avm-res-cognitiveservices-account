resource "azapi_resource" "rai_policy" {
  for_each = var.rai_policies

  type = "Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01"
  body = {
    properties = {
      basePolicyName = each.value.base_policy_name
      mode           = each.value.mode
      contentFilters = try([for c in each.value.content_filters : {
        blocking          = c.blocking
        enabled           = c.enabled
        name              = c.name
        severityThreshold = c.severity_threshold
        source            = c.source
      }], null)
      customBlocklists = try([for c in each.value.custom_block_lists : {
        source        = c.source
        blocklistName = c.block_list_name
        blocking      = c.blocking
      }], null)
    }
  }
  name      = each.value.name
  parent_id = local.resource_block.id
}