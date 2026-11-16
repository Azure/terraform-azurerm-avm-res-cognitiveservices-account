mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id     = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/foundry"
      output = {}
    }
  }
}

mock_provider "azurerm" {}
mock_provider "random" {}
mock_provider "time" {}

variables {
  name               = "foundry"
  parent_id          = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test"
  location           = "eastus"
  kind               = "AIServices"
  sku_name           = "S0"
  local_auth_enabled = false
  enable_telemetry   = false
}

run "no_connections_by_default" {
  command = plan

  assert {
    condition     = length(output.project_connection_resource_ids) == 0 && length(output.project_connection_model_references) == 0
    error_message = "Existing account consumers must not create connections by default."
  }

  assert {
    condition     = azapi_resource.ai_service[0].type == "Microsoft.CognitiveServices/accounts@2025-06-01"
    error_message = "The AIServices account must retain its released API-version default."
  }
}

run "openai_account_default" {
  command = plan

  variables {
    kind = "OpenAI"
  }
  assert {
    condition     = azapi_resource.this[0].type == "Microsoft.CognitiveServices/accounts@2025-06-01"
    error_message = "The OpenAI account must retain its released API-version default."
  }
}

run "aiservices_account_control_overrides" {
  command = plan

  variables {
    resource_types      = { cognitiveservices_accounts = "Microsoft.CognitiveServices/accounts@2025-04-01-preview" }
    ignore_body_changes = { cognitiveservices_accounts = ["properties.allowedFqdnList"] }
  }
  assert {
    condition     = azapi_resource.ai_service[0].type == var.resource_types.cognitiveservices_accounts
    error_message = "AIServices must use the owned root API control; nonempty write-only ignore paths must plan successfully."
  }
}

run "openai_account_control_overrides" {
  command = plan

  variables {
    kind                = "OpenAI"
    resource_types      = { cognitiveservices_accounts = "Microsoft.CognitiveServices/accounts@2025-04-01-preview" }
    ignore_body_changes = { cognitiveservices_accounts = ["properties.allowedFqdnList"] }
  }
  assert {
    condition     = azapi_resource.this[0].type == var.resource_types.cognitiveservices_accounts
    error_message = "OpenAI must use the owned root API control; nonempty write-only ignore paths must plan successfully."
  }
}

run "compose_existing_projects" {
  command = apply

  variables {
    resource_types = {
      cognitiveservices_accounts_projects_connections = {
        cognitiveservices_accounts_projects_connections = "Microsoft.CognitiveServices/accounts/projects/connections@2025-07-01-preview"
      }
    }
    ignore_body_changes = {
      cognitiveservices_accounts_projects_connections = {
        cognitiveservices_accounts_projects_connections = ["properties.metadata.models"]
      }
    }
    retry    = { error_message_regex = ["RequestConflict"], interval_seconds = 3, max_interval_seconds = 9 }
    timeouts = { create = "20m", read = "2m", update = "25m", delete = "15m" }
    project_connections = {
      primary = {
        project_name = "research"
        name         = "enterprise-models"
        target       = "https://gateway.example.com/ai/v1"
        audience     = "api://gateway"
        models       = { chat = { model_name = "gpt-4.1" } }
      }
      secondary = {
        project_name = "development.v1-"
        name         = "development-models"
        target       = "https://gateway.example.com/dev/v1"
        audience     = "https://cognitiveservices.azure.com"
        models       = { small = { model_name = "gpt-4.1-mini", model_version = "2025-04-14" } }
      }
    }
  }

  assert {
    condition = (
      length(output.project_connection_resource_ids) == 2 &&
      output.project_connection_model_references["primary"]["chat"] == "enterprise-models/chat" &&
      output.project_connection_model_references["secondary"]["small"] == "development-models/small"
    )
    error_message = "Parent cardinality and catalog outputs must retain caller keys and gateway aliases."
  }
}

run "reject_project_path" {
  command = plan

  variables {
    project_connections = {
      invalid = {
        project_name = "research/connections/injected"
        name         = "enterprise-models"
        target       = "https://gateway.example.com/ai/v1"
        audience     = "api://gateway"
        models       = { chat = { model_name = "gpt-4.1" } }
      }
    }
  }
  expect_failures = [var.project_connections]
}

run "direct_payload_and_outputs" {
  command = apply

  module {
    source = "./modules/project-connection"
  }

  variables {
    name             = "enterprise-models"
    parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/foundry/projects/research"
    target           = "https://gateway.example.com/ai/foundry/entra/v1"
    audience         = "api://00000000-0000-0000-0000-000000000004"
    enable_telemetry = false
    models = {
      chat     = { model_name = "gpt-4.1", model_version = "2025-04-14" }
      chatmini = { model_name = "gpt-4.1-mini" }
    }
  }

  assert {
    condition = (
      azapi_resource.this.parent_id == var.parent_id &&
      azapi_resource.this.body.properties.category == "ApiManagement" &&
      azapi_resource.this.body.properties.authType == "ProjectManagedIdentity" &&
      azapi_resource.this.body.properties.target == var.target &&
      azapi_resource.this.body.properties.audience == var.audience &&
      !azapi_resource.this.body.properties.isSharedToAll &&
      jsonencode(azapi_resource.this.body.properties.credentials) == "{}" &&
      !azapi_resource.this.schema_validation_enabled
    )
    error_message = "The connection must preserve project scope, exact APIM/auth casing, audience, target and empty object credentials."
  }

  assert {
    condition = jsonencode(azapi_resource.this.body.properties.metadata) == jsonencode({
      deploymentInPath = "false"
      models = jsonencode([
        { name = "chat", properties = { model = { name = "gpt-4.1", version = "2025-04-14", format = "OpenAI" } } },
        { name = "chatmini", properties = { model = { name = "gpt-4.1-mini", version = "", format = "OpenAI" } } }
      ])
    })
    error_message = "Metadata must contain exactly a string deployment toggle and a JSON-string static model list."
  }

  assert {
    condition = (
      output.resource_id == azapi_resource.this.id &&
      output.name == "enterprise-models" &&
      output.model_references == {
        chat     = "enterprise-models/chat"
        chatmini = "enterprise-models/chatmini"
      }
    )
    error_message = "Outputs must expose resource identity and connection/deployment references."
  }
}
