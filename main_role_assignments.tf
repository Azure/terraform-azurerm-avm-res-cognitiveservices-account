locals {
  # Role names are matched case-insensitively, as the AzureRM provider matched them.
  role_definition_ids_by_name = length(var.role_assignments) > 0 ? {
    for definition in data.azapi_resource_list.role_definitions[0].output.results : lower(definition.role_name) => definition.id...
  } : {}
  role_definition_resource_substring = "/providers/microsoft.authorization/roledefinitions/"
  role_assignments = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      # The AzureRM provider sent this principal type when the flag was set, which skips the Entra ID
      # existence check that fails for newly created service principals.
      principal_type = assignment.principal_type == null && assignment.skip_service_principal_aad_check ? "ServicePrincipal" : assignment.principal_type
      # Names resolve to IDs. Tenant-level IDs are qualified with the subscription, which is the form
      # Azure returns, so that the configuration and the deployed assignment compare equal.
      role_definition_id_or_name = (
        !strcontains(lower(assignment.role_definition_id_or_name), local.role_definition_resource_substring) ? try(local.role_definition_ids_by_name[lower(assignment.role_definition_id_or_name)][0], assignment.role_definition_id_or_name) :
        startswith(lower(assignment.role_definition_id_or_name), "/providers/") ? "/subscriptions/${local.subscription_id}${assignment.role_definition_id_or_name}" :
        assignment.role_definition_id_or_name
      )
    })
  }
  subscription_id = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id).subscription_id
}

# Role definitions are listed in the resource group rather than on the account, so the lookup does not
# wait for pending changes to the account and a role name that does not exist fails during plan.
data "azapi_resource_list" "role_definitions" {
  count = length(var.role_assignments) > 0 ? 1 : 0

  parent_id = var.parent_id
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}

module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.9.0"

  location                                  = var.location
  enable_telemetry                          = var.enable_telemetry
  role_assignment_definition_lookup_enabled = false
  role_assignments                          = local.role_assignments
}

resource "azapi_resource" "role_assignments" {
  for_each = var.role_assignments

  name                 = module.avm_interfaces.role_assignments_azapi[each.key].name
  parent_id            = local.resource_id
  type                 = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body                 = module.avm_interfaces.role_assignments_azapi[each.key].body
  ignore_casing        = true
  ignore_null_property = true
  # The AzureRM provider replaced a role assignment whenever one of its inputs changed. The inputs are
  # compared rather than the body, because Azure normalises role definition IDs. While the prior value
  # is null, as it is straight after upgrading from AzureRM, nothing is replaced.
  replace_triggers_external_values = {
    condition                              = each.value.condition
    condition_version                      = each.value.condition_version
    delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
    description                            = each.value.description
    principal_id                           = lower(each.value.principal_id)
    principal_type                         = local.role_assignments[each.key].principal_type
    role_definition_id_or_name             = lower(each.value.role_definition_id_or_name)
  }
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

  lifecycle {
    # Upgraded assignments keep the GUID azurerm generated, while the interfaces module generates a
    # new one. Replacing the assignment would fail with ScopeLocked under a CanNotDelete lock.
    ignore_changes = [name]

    precondition {
      condition     = strcontains(lower(local.role_assignments[each.key].role_definition_id_or_name), local.role_definition_resource_substring)
      error_message = "The role definition `${each.value.role_definition_id_or_name}` was not found in the resource group. Use the name of a role definition that can be assigned there, or the role definition's resource ID."
    }
  }
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}
