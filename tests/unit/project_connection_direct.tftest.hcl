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

run "apim_model_format_override" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    models    = { chat = { model_name = "custom-model", model_format = "Custom" } }
    metadata  = { owner = "example-team" }
    auth_type = "AAD"
  }
  assert {
    condition = (
      jsondecode(azapi_resource.this.body.properties.metadata.models)[0].properties.model.format == "Custom" &&
      azapi_resource.this.body.properties.metadata.owner == "example-team" &&
      azapi_resource.this.body.properties.authType == "AAD" &&
      !contains(keys(azapi_resource.this.body.properties), "credentials")
    )
    error_message = "APIM must honor model format, extra metadata and authentication overrides without retaining project-identity credentials."
  }
}

run "search_aad_body" {
  command = apply
  module {
    source = "./modules/project-connection"
  }
  variables {
    category  = "CognitiveSearch"
    auth_type = "AAD"
    audience  = null
    models    = {}
    target    = "https://search.example.com/"
    metadata  = { ApiType = "Azure", ApiVersion = "2025-09-01" }
  }
  assert {
    condition = (
      jsonencode(azapi_resource.this.body.properties) == jsonencode({
        category = "CognitiveSearch"
        authType = "AAD"
        target   = "https://search.example.com/"
        metadata = { ApiType = "Azure", ApiVersion = "2025-09-01" }
      }) &&
      azapi_resource.this.schema_validation_enabled &&
      length(output.model_references) == 0
    )
    error_message = "A non-APIM connection must use the shared ARM body without audience, APIM catalog metadata or credentials, with schema validation enabled."
  }
}

run "azure_openai_api_key" {
  command = apply
  module {
    source = "./modules/project-connection"
  }
  variables {
    category            = "AzureOpenAI"
    auth_type           = "ApiKey"
    audience            = null
    models              = {}
    credentials         = { key = "unit-test-only" }
    credentials_version = "rotation-2"
  }
  assert {
    condition = (
      azapi_resource.this.body.properties.authType == "ApiKey" &&
      !contains(keys(azapi_resource.this.body.properties), "credentials") &&
      azapi_resource.this.sensitive_body_version["properties.credentials"] == "ApiKey:rotation-2"
    )
    error_message = "Key credentials must be write-only, outside the persisted body, with an explicit rotation version."
  }
}

run "custom_keys_body" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    category    = "CustomKeys"
    auth_type   = "CustomKeys"
    audience    = null
    models      = {}
    target      = "service-specific-target"
    credentials = { header0 = "unit-test-only", header1 = "another-unit-test-value" }
  }
  assert {
    condition     = jsonencode(local.sensitive_bodies["CustomKeys"]) == jsonencode({ properties = { credentials = { keys = var.credentials } } })
    error_message = "Custom key/value entries must be nested under credentials.keys, not flattened into credentials."
  }
}

run "managed_identity_body" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    category  = "AzureBlob"
    auth_type = "ManagedIdentity"
    audience  = null
    models    = {}
    credentials = {
      clientId   = "00000000-0000-0000-0000-000000000002"
      resourceId = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/connection"
    }
  }
  assert {
    condition     = local.sensitive_bodies["ManagedIdentity"].properties.credentials == var.credentials
    error_message = "Managed identity selectors must be serialized as the documented credential fields."
  }
}

run "oauth2_category_credentials" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    category  = "GoogleAdWords"
    auth_type = "OAuth2"
    audience  = null
    models    = {}
    credentials = {
      clientId       = "00000000-0000-0000-0000-000000000002"
      clientSecret   = "unit-test-only"
      developerToken = "unit-test-only"
      refreshToken   = "unit-test-only"
    }
  }
  assert {
    condition     = local.sensitive_bodies["OAuth2"].properties.credentials == var.credentials
    error_message = "OAuth2 must serialize the service-specific credential fields without putting them into the public body."
  }
}

run "foundry_pattern_storage_body" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    category  = "AzureStorageAccount"
    auth_type = "AAD"
    audience  = null
    models    = {}
    target    = "https://examplestorage.blob.core.windows.net/"
    metadata = {
      ResourceId = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/examplestorage"
      location   = "eastus"
    }
  }
  assert {
    condition = (
      jsonencode(azapi_resource.this.body) == jsonencode({
        properties = {
          category = "AzureStorageAccount"
          authType = "AAD"
          target   = "https://examplestorage.blob.core.windows.net/"
          metadata = {
            ApiType    = "Azure"
            ResourceId = var.metadata.ResourceId
            location   = "eastus"
          }
        }
      }) &&
      !azapi_resource.this.schema_validation_enabled
    )
    error_message = "The Foundry pattern's storage-account category must be supported without renaming it to AzureBlob or adding APIM sharing/credential fields."
  }
}

run "foundry_pattern_cosmos_body" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    category  = "CosmosDb"
    auth_type = "AAD"
    audience  = null
    models    = {}
    target    = "https://examplecosmos.documents.azure.com:443/"
    metadata = {
      ResourceId = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.DocumentDB/databaseAccounts/examplecosmos"
      location   = "eastus"
    }
  }
  assert {
    condition = (
      jsonencode(azapi_resource.this.body) == jsonencode({
        properties = {
          category = "CosmosDb"
          authType = "AAD"
          target   = "https://examplecosmos.documents.azure.com:443/"
          metadata = {
            ApiType    = "Azure"
            ResourceId = var.metadata.ResourceId
            location   = "eastus"
          }
        }
      }) &&
      azapi_resource.this.schema_validation_enabled
    )
    error_message = "Cosmos must preserve the pattern's target port, trailing slash and ARM metadata without inventing credential or sharing fields."
  }
}

run "foundry_pattern_search_body" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    category  = "CognitiveSearch"
    auth_type = "AAD"
    audience  = null
    models    = {}
    target    = "https://examplesearch.search.windows.net"
    metadata = {
      ApiVersion = "2024-05-01-preview"
      ResourceId = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Search/searchServices/examplesearch"
      location   = "eastus"
    }
  }
  assert {
    condition = (
      jsonencode(azapi_resource.this.body) == jsonencode({
        properties = {
          category = "CognitiveSearch"
          authType = "AAD"
          target   = "https://examplesearch.search.windows.net"
          metadata = {
            ApiType    = "Azure"
            ApiVersion = "2024-05-01-preview"
            ResourceId = var.metadata.ResourceId
            location   = "eastus"
          }
        }
      }) &&
      azapi_resource.this.schema_validation_enabled
    )
    error_message = "Search must preserve the pattern's service API version, resource ID and location, with no APIM catalog or audience."
  }
}

run "reject_wrong_storage_metadata_resource" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    category  = "AzureStorageAccount"
    auth_type = "AAD"
    audience  = null
    models    = {}
    metadata = {
      ResourceId = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/test/providers/Microsoft.Search/searchServices/examplesearch"
    }
  }
  expect_failures = [var.metadata]
}

run "sharing_override" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    is_shared_to_all = true
  }
  assert {
    condition     = azapi_resource.this.body.properties.isSharedToAll
    error_message = "An explicit sharing override must take precedence over APIM's false default."
  }
}

run "reject_unknown_category" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    category  = "NotAConnectionCategory"
    auth_type = "AAD"
    audience  = null
    models    = {}
  }
  expect_failures = [var.category]
}

run "reject_unknown_authentication" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    auth_type = "NotAnAuthenticationType"
  }
  expect_failures = [var.auth_type]
}

run "reject_missing_key" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    auth_type = "ApiKey"
  }
  expect_failures = [var.credentials]
}

run "reject_credentials_for_keyless_auth" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    credentials = { key = "unit-test-only" }
  }
  expect_failures = [var.credentials]
}

run "reject_oauth2_missing_category_field" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    category    = "Xero"
    auth_type   = "OAuth2"
    audience    = null
    models      = {}
    credentials = { clientId = "00000000-0000-0000-0000-000000000002", clientSecret = "unit-test-only" }
  }
  expect_failures = [var.credentials]
}

run "reject_reserved_apim_metadata" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    metadata = { models = "[]" }
  }
  expect_failures = [var.metadata]
}

run "reject_apim_without_audience" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    audience = null
  }
  expect_failures = [var.audience]
}

run "reject_blank_format" {
  command = plan
  module {
    source = "./modules/project-connection"
  }
  variables {
    models = { chat = { model_name = "gpt-4.1", model_format = " " } }
  }
  expect_failures = [var.models]
}
