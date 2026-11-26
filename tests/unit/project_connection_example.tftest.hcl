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
  target = azapi_resource.project
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
      output.resource_id == "${azapi_resource.project.id}/connections/enterprise-models" &&
      output.model_references["chat"] == "enterprise-models/chat" &&
      azapi_resource.project.parent_id == azapi_resource.account.id &&
      azapi_resource.resource_group.parent_id == data.azapi_client_config.this.subscription_resource_id &&
      azapi_resource.account.body.properties.allowProjectManagement &&
      azapi_resource.account.body.properties.disableLocalAuth &&
      azapi_resource.gateway.body.sku.name == "Premium" &&
      azapi_resource.gateway.body.sku.capacity == 2 &&
      toset(azapi_resource.gateway.body.zones) == toset(["1", "2"])
    )
    error_message = "The example must always create its own project, model-backed gateway and keyless prerequisites across two zones."
  }

  assert {
    condition = (
      azapi_resource.model["chat"].name == "chat" &&
      azapi_resource.model["chat"].body.properties.model.name == var.models["chat"].model_name &&
      azapi_resource.model["chat"].body.properties.model.version == var.models["chat"].model_version &&
      azapi_resource.gateway_api.body.properties.path == "ai/v1" &&
      azapi_resource.gateway_api.body.properties.serviceUrl == "https://fixture.openai.azure.com/openai/v1" &&
      azapi_resource.chat_completions.body.properties.method == "POST" &&
      azapi_resource.chat_completions.body.properties.urlTemplate == "/chat/completions" &&
      azapi_resource.gateway_policy.body.properties.format == "xml" &&
      azapi_resource.gateway_policy.delete_headers["If-Match"] == "*" &&
      strcontains(azapi_resource.gateway_policy.body.properties.value, "<policies>\r\n\t<inbound>") &&
      strcontains(azapi_resource.gateway_policy.body.properties.value, "\r\n\t<backend>\r\n\t\t<base />\r\n\t</backend>") &&
      endswith(azapi_resource.gateway_policy.body.properties.value, "\r\n</policies>") &&
      strcontains(azapi_resource.gateway_policy.body.properties.value, "<validate-azure-ad-token") &&
      strcontains(azapi_resource.gateway_policy.body.properties.value, "<claim name=\"oid\" match=\"all\">") &&
      strcontains(azapi_resource.gateway_policy.body.properties.value, "<value>${azapi_resource.project.identity[0].principal_id}</value>") &&
      strcontains(azapi_resource.gateway_policy.body.properties.value, "<audience>https://cognitiveservices.azure.com</audience>") &&
      strcontains(azapi_resource.gateway_policy.body.properties.value, "<authentication-managed-identity resource=\"https://cognitiveservices.azure.com\" />") &&
      azapi_resource.gateway_openai_user.body.properties.principalId == azapi_resource.gateway.identity[0].principal_id &&
      endswith(azapi_resource.gateway_openai_user.body.properties.roleDefinitionId, "/5e0bd9bd-7b93-4f28-af87-19fc36ad61bd") &&
      azapi_resource.gateway_openai_user.parent_id == azapi_resource.account.id
    )
    error_message = "The example must preserve XML normalization, conditional-delete header, token validation and model backend authorization."
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
      output.model_references["large"] == "research-models/large" &&
      length(azapi_resource.model) == 2 &&
      azapi_resource.model["small"].name == "small" &&
      !contains(keys(azapi_resource.model["small"].body.properties.model), "version") &&
      azapi_resource.model["large"].body.properties.model.version == "2025-04-14"
    )
    error_message = "The example must pass the selected catalog through and deploy matching aliases, omitting an unspecified version."
  }

  assert {
    condition = (
      azapi_resource.project.locks == tolist([azapi_resource.account.id]) &&
      alltrue([for deployment in azapi_resource.model : deployment.locks == azapi_resource.project.locks])
    )
    error_message = "The project and every model must retain the shared account lock."
  }
}
