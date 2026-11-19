mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.CognitiveServices/accounts/example-foundry/projects/research/connections/enterprise-models"
      output = {
        properties = {
          gatewayUrl = "https://fixture.azure-api.net"
          endpoints = {
            "OpenAI Language Model Instance API" = "https://fixture.openai.azure.com/"
          }
        }
      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
      tenant_id                = "11111111-1111-1111-1111-111111111111"
    }
  }
}

mock_provider "random" {}

override_resource {
  target = azapi_resource.project[0]
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.CognitiveServices/accounts/example-foundry/projects/research"
  }
}

run "runnable_example_provisions_prerequisites" {
  command = apply

  module {
    source = "./examples/project-connection"
  }

  assert {
    condition = (
      output.name == "enterprise-models" &&
      output.resource_id == "${azapi_resource.project[0].id}/connections/enterprise-models" &&
      output.model_references["chat"] == "enterprise-models/chat"
    )
    error_message = "The no-input runnable example must create a project and expose the local child's connection ID and default catalog reference."
  }

  assert {
    condition = (
      local.parent_id == azapi_resource.project[0].id &&
      local.target == "${azapi_resource.gateway[0].output.properties.gatewayUrl}/ai/v1" &&
      local.audience == "https://cognitiveservices.azure.com" &&
      azapi_resource.project[0].parent_id == azapi_resource.account[0].id &&
      azapi_resource.resource_group[0].parent_id == data.azapi_client_config.this.subscription_resource_id &&
      azapi_resource.account[0].body.properties.allowProjectManagement &&
      azapi_resource.account[0].body.properties.disableLocalAuth &&
      azapi_resource.gateway[0].body.sku.name == "Premium" &&
      azapi_resource.gateway[0].body.sku.capacity == 2 &&
      toset(azapi_resource.gateway[0].body.zones) == toset(["1", "2"])
    )
    error_message = "Fixture inputs must derive from Terraform-owned prerequisites with keyless auth and two Premium gateway units across zones 1 and 2."
  }

  assert {
    condition = (
      azapi_resource.model["chat"].name == "chat" &&
      azapi_resource.model["chat"].body.properties.model.name == var.models["chat"].model_name &&
      azapi_resource.model["chat"].body.properties.model.version == var.models["chat"].model_version &&
      azapi_resource.gateway_api[0].body.properties.path == "ai/v1" &&
      azapi_resource.gateway_api[0].body.properties.serviceUrl == "https://fixture.openai.azure.com/openai/v1" &&
      azapi_resource.chat_completions[0].body.properties.method == "POST" &&
      azapi_resource.chat_completions[0].body.properties.urlTemplate == "/chat/completions" &&
      azapi_resource.gateway_policy[0].body.properties.format == "xml" &&
      strcontains(azapi_resource.gateway_policy[0].body.properties.value, "<policies>\r\n\t<inbound>") &&
      strcontains(azapi_resource.gateway_policy[0].body.properties.value, "\r\n\t<backend>\r\n\t\t<base />\r\n\t</backend>") &&
      endswith(azapi_resource.gateway_policy[0].body.properties.value, "\r\n</policies>") &&
      strcontains(azapi_resource.gateway_policy[0].body.properties.value, "<validate-azure-ad-token") &&
      strcontains(azapi_resource.gateway_policy[0].body.properties.value, "<claim name=\"oid\" match=\"all\">") &&
      strcontains(azapi_resource.gateway_policy[0].body.properties.value, "<value>${azapi_resource.project[0].identity[0].principal_id}</value>") &&
      strcontains(azapi_resource.gateway_policy[0].body.properties.value, "<audience>${local.audience}</audience>") &&
      strcontains(azapi_resource.gateway_policy[0].body.properties.value, "<authentication-managed-identity resource=\"https://cognitiveservices.azure.com\" />") &&
      azapi_resource.gateway_openai_user[0].body.properties.principalId == azapi_resource.gateway[0].identity[0].principal_id &&
      endswith(azapi_resource.gateway_openai_user[0].body.properties.roleDefinitionId, "/5e0bd9bd-7b93-4f28-af87-19fc36ad61bd") &&
      azapi_resource.gateway_openai_user[0].parent_id == azapi_resource.account[0].id
    )
    error_message = "The fixture must configure a real model-backed Chat Completions route, validate project tokens and use managed identity for the backend."
  }
}

run "runnable_example_catalog_override" {
  command = apply

  module {
    source = "./examples/project-connection"
  }

  variables {
    name = "research-models"
    models = {
      small = { model_name = "gpt-4.1-mini" }
      large = { model_name = "gpt-4.1", model_version = "2025-04-14" }
    }
  }

  assert {
    condition = (
      output.name == "research-models" &&
      length(output.model_references) == 2 &&
      output.model_references["small"] == "research-models/small" &&
      output.model_references["large"] == "research-models/large"
    )
    error_message = "The runnable example must pass caller-selected connection names and gateway catalogs through to the child."
  }

  assert {
    condition = (
      length(azapi_resource.model) == 2 &&
      azapi_resource.model["small"].name == "small" &&
      !contains(keys(azapi_resource.model["small"].body.properties.model), "version") &&
      azapi_resource.model["large"].body.properties.model.version == "2025-04-14"
    )
    error_message = "Fixture deployments must match the selected aliases, omitting an unspecified model version."
  }

  assert {
    condition = (
      azapi_resource.project[0].locks == tolist([azapi_resource.account[0].id]) &&
      alltrue([
        for deployment in azapi_resource.model :
        deployment.locks == azapi_resource.project[0].locks
      ])
    )
    error_message = "The project and every model deployment must share the account-scoped AzAPI lock to avoid concurrent account operations."
  }
}

run "external_project_and_gateway_create_no_fixture" {
  command = apply

  module {
    source = "./examples/project-connection"
  }

  variables {
    parent_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/external/providers/Microsoft.CognitiveServices/accounts/external/projects/external"
    target    = "https://external.azure-api.net/models/v1"
    audience  = "api://external-gateway"
  }

  assert {
    condition = (
      local.parent_id == var.parent_id &&
      local.target == var.target &&
      local.audience == var.audience &&
      length(random_string.suffix) == 0 &&
      length(azapi_resource.resource_group) == 0 &&
      length(azapi_resource.account) == 0 &&
      length(azapi_resource.project) == 0 &&
      length(azapi_resource.model) == 0 &&
      length(azapi_resource.gateway) == 0 &&
      length(azapi_resource.gateway_api) == 0 &&
      length(azapi_resource.chat_completions) == 0 &&
      length(azapi_resource.gateway_policy) == 0 &&
      length(azapi_resource.gateway_openai_user) == 0
    )
    error_message = "External-project mode must pass through the exact caller inputs and must not create or adopt any prerequisite resources."
  }
}

run "reject_partial_external_inputs" {
  command = plan

  module {
    source = "./examples/project-connection"
  }

  variables {
    parent_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/external/providers/Microsoft.CognitiveServices/accounts/external/projects/external"
  }

  expect_failures = [var.parent_id]
}
