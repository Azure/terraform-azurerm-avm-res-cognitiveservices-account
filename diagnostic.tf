locals {
  # Azure reports a diagnostic setting with every category and category group it offers, so the
  # module sends the full set with explicit enabled flags rather than only the selected entries.
  diagnostic_categories = try(data.azapi_resource_list.diagnostic_categories[0].output.categories, [])
  available_log_categories = sort([
    for category in local.diagnostic_categories : category.name if category.category_type == "Logs"
  ])
  available_log_category_groups = sort(distinct(flatten([
    for category in local.diagnostic_categories : coalesce(category.groups, []) if category.category_type == "Logs"
  ])))
  available_metric_categories = sort([
    for category in local.diagnostic_categories : category.name if category.category_type == "Metrics"
  ])
}

# The categories and category groups the account offers.
data "azapi_resource_list" "diagnostic_categories" {
  count = length(var.diagnostic_settings) > 0 ? 1 : 0

  parent_id = local.resource_id
  type      = "Microsoft.Insights/diagnosticSettingsCategories@2021-05-01-preview"
  response_export_values = {
    categories = "value[].{name: name, category_type: properties.categoryType, groups: properties.categoryGroups}"
  }
}

resource "azapi_resource" "diagnostic_settings" {
  for_each = var.diagnostic_settings

  name      = coalesce(each.value.name, "diag-${var.name}")
  parent_id = local.resource_id
  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
  body = {
    properties = {
      eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
      eventHubName                = each.value.event_hub_name
      logAnalyticsDestinationType = each.value.log_analytics_destination_type
      # Groups and individual categories cannot be combined in one diagnostic setting, so only the
      # dimension the caller uses is expanded.
      logs = tolist(concat(
        [for group in local.available_log_category_groups : {
          category      = null
          categoryGroup = group
          enabled       = contains(each.value.log_groups, group)
        } if length(each.value.log_groups) > 0],
        [for category in local.available_log_categories : {
          category      = category
          categoryGroup = null
          enabled       = contains(each.value.log_categories, category)
        } if length(each.value.log_categories) > 0],
      ))
      marketplacePartnerId = each.value.marketplace_partner_resource_id
      metrics = tolist([for category in local.available_metric_categories : {
        category = category
        enabled  = contains(each.value.metric_categories, category)
      }])
      storageAccountId = each.value.storage_account_resource_id
      workspaceId      = each.value.workspace_resource_id
    }
  }
  ignore_null_property   = true
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

moved {
  from = azurerm_monitor_diagnostic_setting.this
  to   = azapi_resource.diagnostic_settings
}
