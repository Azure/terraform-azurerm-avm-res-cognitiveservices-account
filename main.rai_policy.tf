module "rai_policy" {
  source   = "./modules/rai_policy"
  for_each = var.rai_policies

  base_policy_name   = each.value.base_policy_name
  mode               = each.value.mode
  name               = each.value.name
  cognitive_account_id          = azurerm_cognitive_account.cognitive_account.id
  content_filters    = each.value.content_filters
  timeouts           = each.value.timeouts != null ? each.value.timeouts : var.timeouts
}
