mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/foundry/projects/research/connections/enterprise-models"
    }
  }
}

variables {
  audience         = "api://gateway"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/foundry/projects/research"
  target           = "https://gateway.example.com/ai/v1"
  enable_telemetry = false
}

run "runnable_example_defaults" {
  command = apply

  module {
    source = "./examples/project-connection"
  }

  assert {
    condition = (
      output.name == "enterprise-models" &&
      output.resource_id == "${var.parent_id}/connections/enterprise-models" &&
      output.model_references["chat"] == "enterprise-models/chat"
    )
    error_message = "The runnable example must deploy the local child and expose its connection ID and default catalog reference."
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
}
