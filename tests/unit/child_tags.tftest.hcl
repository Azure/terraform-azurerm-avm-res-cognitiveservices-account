mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.CognitiveServices/accounts/unit-account"
      output = {}
      tags   = { provider_default = "unset" }
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

mock_provider "modtm" {}

mock_provider "random" {
  mock_resource "random_string" {
    defaults = {
      result = "abcde"
    }
  }
}

mock_provider "time" {}

variables {
  enable_telemetry   = false
  kind               = "OpenAI"
  local_auth_enabled = false
  location           = "eastus"
  name               = "unit-account"
  parent_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit"
  sku_name           = "S0"
  tags               = { account_only = "not-inherited" }
}

run "child_tag_bindings" {
  command = apply

  variables {
    cognitive_deployments = {
      omitted = {
        name  = "deployment-omitted"
        model = { format = "OpenAI", name = "gpt-4o" }
        scale = { type = "Standard" }
      }
      explicit_null = {
        name  = "deployment-null"
        model = { format = "OpenAI", name = "gpt-4o" }
        scale = { type = "Standard" }
        tags  = null
      }
      supplied = {
        name  = "deployment-supplied"
        model = { format = "OpenAI", name = "gpt-4o" }
        scale = { type = "Standard" }
        tags  = { child = "deployment" }
      }
      empty = {
        name  = "deployment-empty"
        model = { format = "OpenAI", name = "gpt-4o" }
        scale = { type = "Standard" }
        tags  = {}
      }
    }
    rai_policies = {
      omitted = {
        name             = "policy-omitted"
        base_policy_name = "Microsoft.Default"
        mode             = "Default"
      }
      explicit_null = {
        name             = "policy-null"
        base_policy_name = "Microsoft.Default"
        mode             = "Default"
        tags             = null
      }
      supplied = {
        name             = "policy-supplied"
        base_policy_name = "Microsoft.Default"
        mode             = "Default"
        tags             = { child = "rai-policy" }
      }
      empty = {
        name             = "policy-empty"
        base_policy_name = "Microsoft.Default"
        mode             = "Default"
        tags             = {}
      }
    }
  }

  assert {
    condition = (
      module.deployment["omitted"].tags == tomap({ provider_default = "unset" }) &&
      module.deployment["explicit_null"].tags == tomap({ provider_default = "unset" }) &&
      module.deployment["supplied"].tags == tomap({ child = "deployment" }) &&
      length(module.deployment["empty"].tags) == 0
    )
    error_message = "Deployment tags must reach the resource, preserving omitted/null defaults and explicit empty maps without account-tag inheritance."
  }

  assert {
    condition = (
      module.rai_policy["omitted"].tags == tomap({ provider_default = "unset" }) &&
      module.rai_policy["explicit_null"].tags == tomap({ provider_default = "unset" }) &&
      module.rai_policy["supplied"].tags == tomap({ child = "rai-policy" }) &&
      length(module.rai_policy["empty"].tags) == 0
    )
    error_message = "RAI policy tags must reach the resource, preserving omitted/null defaults and explicit empty maps without account-tag inheritance."
  }

  assert {
    condition = (
      alltrue([for key, deployment in module.deployment : deployment.name == var.cognitive_deployments[key].name && deployment.resource.cognitive_account_id == output.resource_id]) &&
      alltrue([for key, policy in module.rai_policy : policy.name == var.rai_policies[key].name]) &&
      output.resource.tags == var.tags
    )
    error_message = "Child tagging must not change deployment parents, child names or the account's tags."
  }
}
