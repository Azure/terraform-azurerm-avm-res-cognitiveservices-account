resource "azapi_resource" "rai_policy" {
  for_each  = var.rai_policies
  type      = "Microsoft.CognitiveServices/accounts/raiPolicies@${var.rai_policy_api_version}"
  parent_id = azurerm_cognitive_account.this.id
  name      = each.value.name
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
}