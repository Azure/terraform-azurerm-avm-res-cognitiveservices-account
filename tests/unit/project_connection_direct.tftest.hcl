mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

variables {
  name             = "enterprise-models"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/foundry/projects/research"
  target           = "https://gateway.example.com/ai/foundry/entra/v1"
  audience         = "api://00000000-0000-0000-0000-000000000004"
  enable_telemetry = false
  models           = { chat = { model_name = "gpt-4.1" } }
}

run "control_overrides" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    resource_types = {
      cognitiveservices_accounts_projects_connections = "Microsoft.CognitiveServices/accounts/projects/connections@2025-07-01-preview"
    }
    retry               = { error_message_regex = ["RequestConflict"], interval_seconds = 3, max_interval_seconds = 9 }
    timeouts            = { create = "20m", read = "2m", update = "25m", delete = "15m" }
    ignore_body_changes = { cognitiveservices_accounts_projects_connections = ["properties.metadata.models"] }
  }
  assert {
    condition = (
      azapi_resource.this.type == var.resource_types.cognitiveservices_accounts_projects_connections &&
      azapi_resource.this.retry.interval_seconds == 3 &&
      azapi_resource.this.retry.max_interval_seconds == 9 &&
      azapi_resource.this.timeouts.create == "20m" &&
      azapi_resource.this.timeouts.read == "2m" &&
      azapi_resource.this.timeouts.update == "25m" &&
      azapi_resource.this.timeouts.delete == "15m"
    )
    error_message = "API type, retry and all timeouts must honor consumer overrides; nonempty write-only ignore paths must plan successfully."
  }
}

run "null_controls" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    timeouts = null
    retry    = null
  }
  assert {
    condition     = azapi_resource.this.timeouts == null && azapi_resource.this.retry == null
    error_message = "Null controls must use provider defaults."
  }
}

run "reject_scope_audience" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    audience = "api://gateway/.default"
  }
  expect_failures = [var.audience]
}

run "reject_guid_audience" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    audience = "00000000-0000-0000-0000-000000000004"
  }
  expect_failures = [var.audience]
}

run "reject_operation_target" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    target = "https://gateway.example.com/openai/v1/chat/completions"
  }
  expect_failures = [var.target]
}

run "reject_query_target" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    target = "https://gateway.example.com/openai/v1?api-version=2025-01-01"
  }
  expect_failures = [var.target]
}

run "reject_responses_target" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    target = "https://gateway.example.com/openai/v1/responses"
  }
  expect_failures = [var.target]
}

run "reject_deployment_target" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    target = "https://gateway.example.com/openai/deployments/chat"
  }
  expect_failures = [var.target]
}

run "reject_insecure_target" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    target = "http://gateway.example.com/openai/v1"
  }
  expect_failures = [var.target]
}

run "reject_trailing_slash" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    target = "https://gateway.example.com/openai/v1/"
  }
  expect_failures = [var.target]
}

run "reject_empty_models" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    models = {}
  }
  expect_failures = [var.models]
}

run "reject_blank_model" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    models = { chat = { model_name = " " } }
  }
  expect_failures = [var.models]
}

run "reject_invalid_deployment_name" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    models = { "invalid/name" = { model_name = "gpt-4.1" } }
  }
  expect_failures = [var.models]
}

run "reject_invalid_connection_name" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    name = "invalid/name"
  }
  expect_failures = [var.name]
}

run "reject_account_parent" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/foundry"
  }
  expect_failures = [var.parent_id]
}

run "telemetry_requires_location" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    enable_telemetry = true
  }
  expect_failures = [var.location]
}

run "telemetry_disabled_without_location" {
  command = apply
  module {
    source = "./modules/project-connection"
  }
  assert {
    condition = (
      length(azapi_resource.telemetry) == 0 &&
      length(terraform_data.telemetry) == 0 &&
      length(data.azapi_client_config.telemetry) == 0 &&
      azapi_resource.this.name == var.name
    )
    error_message = "Opting out without a location must create only the connection, without telemetry resources or client lookup."
  }
}

run "telemetry_enabled" {
  command = apply
  module {
    source = "./modules/project-connection"
  }
  variables {
    enable_telemetry = true
    location         = "westus3"
  }
  assert {
    condition = (
      length(azapi_resource.telemetry) == 1 &&
      length(terraform_data.telemetry) == 1 &&
      azapi_resource.telemetry[0].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000" &&
      azapi_resource.telemetry[0].location == var.location &&
      startswith(azapi_resource.telemetry[0].name, "${jsondecode(file("./modules/project-connection/metadata.json")).telemetryIdPrefix}.") &&
      length(azapi_resource.telemetry[0].name) <= 64 &&
      azapi_resource.telemetry[0].body.properties.mode == "Incremental" &&
      length(azapi_resource.telemetry[0].body.properties.template.resources) == 0 &&
      azapi_resource.this.name == var.name
    )
    error_message = "Telemetry must deploy one empty subscription-scoped template using the child metadata and requested region without changing the connection."
  }
}
