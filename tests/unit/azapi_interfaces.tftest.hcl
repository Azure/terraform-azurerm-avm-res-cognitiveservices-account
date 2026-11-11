mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.CognitiveServices/accounts/unit-account"
      output = {}
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {}



mock_provider "random" {
  mock_resource "random_string" {
    defaults = {
      result = "abcde"
    }
  }
}

mock_provider "time" {}

override_data {
  target = data.azapi_resource_list.role_definitions
  values = {
    output = {
      results = [
        {
          id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/a97b65f3-24c7-4388-baec-2e87135dc908"
          role_name = "Cognitive Services User"
        },
        {
          id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
          role_name = "Reader"
        },
      ]
    }
  }
}

override_data {
  target = data.azapi_resource_list.diagnostic_categories
  values = {
    output = {
      categories = [
        { name = "Audit", category_type = "Logs", groups = ["audit", "allLogs"] },
        { name = "RequestResponse", category_type = "Logs", groups = ["allLogs"] },
        { name = "AllMetrics", category_type = "Metrics", groups = null },
      ]
    }
  }
}

variables {
  enable_telemetry   = false
  kind               = "OpenAI"
  local_auth_enabled = false
  location           = "eastus"
  name               = "unit-account"
  parent_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit"
  sku_name           = "S0"
}

run "lock_keeps_azurerm_name_and_notes" {
  command = apply

  variables {
    lock = {
      kind = "CanNotDelete"
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "lock-CanNotDelete"
    error_message = "The lock name MUST default to lock-<kind>, as the azurerm resource did."
  }

  assert {
    condition     = azapi_resource.lock[0].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.CognitiveServices/accounts/unit-account"
    error_message = "The lock MUST be scoped to the account."
  }

  assert {
    condition     = azapi_resource.lock[0].body.properties.level == "CanNotDelete" && azapi_resource.lock[0].body.properties.notes == "Cannot delete the resource or its child resources."
    error_message = "The lock level and notes MUST match the azurerm resource."
  }
}

run "no_lock_by_default" {
  command = plan

  assert {
    condition     = length(azapi_resource.lock) == 0 && length(time_sleep.lock_removal) == 0
    error_message = "No lock MUST be planned when var.lock is null."
  }
}

run "role_assignments_resolve_names_and_ids" {
  command = apply

  variables {
    role_assignments = {
      by_name = {
        role_definition_id_or_name = "cognitive services user"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
      non_cognitive_name = {
        role_definition_id_or_name       = "Reader"
        principal_id                     = "00000000-0000-0000-0000-000000000002"
        skip_service_principal_aad_check = true
      }
      tenant_level_id = {
        role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        principal_id               = "00000000-0000-0000-0000-000000000003"
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["by_name"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/a97b65f3-24c7-4388-baec-2e87135dc908"
    error_message = "Role names MUST resolve case-insensitively to the role definition ID."
  }

  assert {
    condition     = azapi_resource.role_assignments["non_cognitive_name"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
    error_message = "Role names without \"Cognitive Services\" MUST resolve too."
  }

  assert {
    condition     = azapi_resource.role_assignments["non_cognitive_name"].body.properties.principalType == "ServicePrincipal"
    error_message = "skip_service_principal_aad_check MUST send the ServicePrincipal principal type."
  }

  assert {
    condition     = azapi_resource.role_assignments["tenant_level_id"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
    error_message = "Tenant-level role definition IDs MUST be qualified with the subscription."
  }
}

run "role_assignment_unknown_name_fails" {
  command = plan

  variables {
    role_assignments = {
      missing = {
        role_definition_id_or_name = "Does Not Exist"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
    }
  }

  expect_failures = [azapi_resource.role_assignments["missing"]]
}

run "diagnostic_settings_send_explicit_flags" {
  command = apply

  variables {
    diagnostic_settings = {
      law = {
        log_groups            = ["audit"]
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.OperationalInsights/workspaces/law"
      }
    }
  }

  assert {
    condition     = azapi_resource.diagnostic_settings["law"].name == "diag-unit-account"
    error_message = "The diagnostic setting name MUST default to diag-<name>, as the azurerm resource did."
  }

  assert {
    condition = azapi_resource.diagnostic_settings["law"].body.properties.logs == tolist([
      { category = null, categoryGroup = "allLogs", enabled = false },
      { category = null, categoryGroup = "audit", enabled = true },
    ])
    error_message = "Every category group MUST be sent with an explicit enabled flag."
  }

  assert {
    condition     = azapi_resource.diagnostic_settings["law"].body.properties.metrics == tolist([{ category = "AllMetrics", enabled = true }])
    error_message = "Metric categories MUST be sent with an explicit enabled flag."
  }

  assert {
    condition     = azapi_resource.diagnostic_settings["law"].body.properties.logAnalyticsDestinationType == "Dedicated"
    error_message = "The destination type MUST be sent as given, as the azurerm resource did."
  }
}
