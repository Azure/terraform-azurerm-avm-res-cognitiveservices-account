data "azapi_client_config" "this" {}

resource "random_string" "suffix" {
  count = local.create_fixture ? 1 : 0

  length  = 12
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  count = local.create_fixture ? 1 : 0

  location               = var.location
  name                   = "rg-project-connection-${random_string.suffix[0].result}"
  parent_id              = data.azapi_client_config.this.subscription_resource_id
  type                   = "Microsoft.Resources/resourceGroups@2025-04-01"
  body                   = {}
  response_export_values = []
}

resource "azapi_resource" "account" {
  count = local.create_fixture ? 1 : 0

  location  = var.location
  name      = "foundry-${random_string.suffix[0].result}"
  parent_id = azapi_resource.resource_group[0].id
  type      = "Microsoft.CognitiveServices/accounts@2025-04-01-preview"
  body = {
    kind = "AIServices"
    sku  = { name = "S0" }
    properties = {
      allowProjectManagement = true
      customSubDomainName    = "foundry-${random_string.suffix[0].result}"
      disableLocalAuth       = true
      publicNetworkAccess    = "Enabled"
    }
  }
  response_export_values = ["properties.endpoints"]

  identity {
    type = "SystemAssigned"
  }
}

resource "azapi_resource" "project" {
  count = local.create_fixture ? 1 : 0

  location  = var.location
  name      = "research"
  parent_id = azapi_resource.account[0].id
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview"
  body = {
    properties = {
      displayName = "Connection example"
      description = "Isolated project for the standalone connection example."
    }
  }
  response_export_values = []

  identity {
    type = "SystemAssigned"
  }
}

resource "azapi_resource" "model" {
  for_each = local.create_fixture ? var.models : {}

  name      = each.key
  parent_id = azapi_resource.account[0].id
  type      = "Microsoft.CognitiveServices/accounts/deployments@2025-04-01-preview"
  body = {
    sku = {
      name     = "GlobalStandard"
      capacity = 1
    }
    properties = {
      model = merge({
        format = "OpenAI"
        name   = each.value.model_name
      }, each.value.model_version == "" ? {} : { version = each.value.model_version })
    }
  }
  response_export_values = []
}

resource "azapi_resource" "gateway" {
  count = local.create_fixture ? 1 : 0

  location  = var.location
  name      = "apim-${random_string.suffix[0].result}"
  parent_id = azapi_resource.resource_group[0].id
  type      = "Microsoft.ApiManagement/service@2024-05-01"
  body = {
    sku = {
      name     = "Premium"
      capacity = 2
    }
    zones = ["1", "2"]
    properties = {
      publisherName  = "AVM connection example"
      publisherEmail = "avm-tests@example.com"
    }
  }
  response_export_values = ["properties.gatewayUrl"]

  identity {
    type = "SystemAssigned"
  }
}

resource "azapi_resource" "gateway_openai_user" {
  count = local.create_fixture ? 1 : 0

  name      = uuidv5("url", "${azapi_resource.account[0].id}/${azapi_resource.gateway[0].id}/openai-user")
  parent_id = azapi_resource.account[0].id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.gateway[0].identity[0].principal_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = "${data.azapi_client_config.this.subscription_resource_id}/providers/Microsoft.Authorization/roleDefinitions/5e0bd9bd-7b93-4f28-af87-19fc36ad61bd"
    }
  }
  response_export_values = []
}

resource "azapi_resource" "gateway_api" {
  count = local.create_fixture ? 1 : 0

  name      = "chat-completions"
  parent_id = azapi_resource.gateway[0].id
  type      = "Microsoft.ApiManagement/service/apis@2024-05-01"
  body = {
    properties = {
      displayName          = "OpenAI Chat Completions"
      path                 = "ai/v1"
      protocols            = ["https"]
      serviceUrl           = "${trimsuffix(azapi_resource.account[0].output.properties.endpoints["OpenAI Language Model Instance API"], "/")}/openai/v1"
      subscriptionRequired = false
    }
  }
  response_export_values = []
}

resource "azapi_resource" "chat_completions" {
  count = local.create_fixture ? 1 : 0

  name      = "chat-completions"
  parent_id = azapi_resource.gateway_api[0].id
  type      = "Microsoft.ApiManagement/service/apis/operations@2024-05-01"
  body = {
    properties = {
      displayName = "Chat completions"
      method      = "POST"
      urlTemplate = "/chat/completions"
    }
  }
  response_export_values = []
}

resource "azapi_resource" "gateway_policy" {
  count = local.create_fixture ? 1 : 0

  name      = "policy"
  parent_id = azapi_resource.gateway_api[0].id
  type      = "Microsoft.ApiManagement/service/apis/policies@2024-05-01"
  body = {
    properties = {
      format = "rawxml"
      value  = <<-XML
        <policies>
          <inbound>
            <base />
            <validate-azure-ad-token tenant-id="${data.azapi_client_config.this.tenant_id}" header-name="Authorization">
              <audiences>
                <audience>${local.audience}</audience>
              </audiences>
              <required-claims>
                <claim name="oid" match="all">
                  <value>${azapi_resource.project[0].identity[0].principal_id}</value>
                </claim>
              </required-claims>
            </validate-azure-ad-token>
            <authentication-managed-identity resource="https://cognitiveservices.azure.com" />
          </inbound>
          <backend><base /></backend>
          <outbound><base /></outbound>
          <on-error><base /></on-error>
        </policies>
      XML
    }
  }
  response_export_values = []

  depends_on = [azapi_resource.gateway_openai_user]
}
