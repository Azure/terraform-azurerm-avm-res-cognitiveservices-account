data "azapi_client_config" "this" {}

resource "random_string" "suffix" {
  length  = 12
  lower   = true
  numeric = false
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  location               = var.location
  name                   = "rg-project-connection-${random_string.suffix.result}"
  parent_id              = data.azapi_client_config.this.subscription_resource_id
  type                   = "Microsoft.Resources/resourceGroups@2025-04-01"
  body                   = {}
  response_export_values = []
}

resource "azapi_resource" "account" {
  location  = var.location
  name      = "foundry-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.CognitiveServices/accounts@2025-04-01-preview"
  body = {
    kind = "AIServices"
    sku  = { name = "S0" }
    properties = {
      allowProjectManagement = true
      customSubDomainName    = "foundry-${random_string.suffix.result}"
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
  location  = var.location
  name      = "research"
  parent_id = azapi_resource.account.id
  type      = "Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview"
  body = {
    properties = {
      displayName = "Connection example"
      description = "Isolated project for the standalone connection example."
    }
  }
  locks                  = [azapi_resource.account.id]
  response_export_values = []

  identity {
    type = "SystemAssigned"
  }
}

resource "azapi_resource" "model" {
  for_each = var.models

  name      = each.key
  parent_id = azapi_resource.account.id
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
  locks                  = [azapi_resource.account.id]
  response_export_values = []

  depends_on = [azapi_resource.project]
}

resource "azapi_resource" "gateway" {
  location  = var.location
  name      = "apim-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
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

  timeouts {
    create = "60m"
    delete = "60m"
    update = "60m"
  }
}

resource "azapi_resource" "gateway_openai_user" {
  name      = uuidv5("url", "${azapi_resource.account.id}/${azapi_resource.gateway.id}/openai-user")
  parent_id = azapi_resource.account.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = azapi_resource.gateway.identity[0].principal_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = "${data.azapi_client_config.this.subscription_resource_id}/providers/Microsoft.Authorization/roleDefinitions/5e0bd9bd-7b93-4f28-af87-19fc36ad61bd"
    }
  }
  response_export_values = []
}

resource "azapi_resource" "gateway_api" {
  name      = "chat-completions"
  parent_id = azapi_resource.gateway.id
  type      = "Microsoft.ApiManagement/service/apis@2024-05-01"
  body = {
    properties = {
      displayName          = "OpenAI Chat Completions"
      path                 = "ai/v1"
      protocols            = ["https"]
      serviceUrl           = "${trimsuffix(azapi_resource.account.output.properties.endpoints["OpenAI Language Model Instance API"], "/")}/openai/v1"
      subscriptionRequired = false
    }
  }
  response_export_values = []
}

resource "azapi_resource" "chat_completions" {
  name      = "chat-completions"
  parent_id = azapi_resource.gateway_api.id
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
  name      = "policy"
  parent_id = azapi_resource.gateway_api.id
  type      = "Microsoft.ApiManagement/service/apis/policies@2024-05-01"
  body = {
    properties = {
      format = "xml"
      value = replace(trimspace(replace(<<-XML
        <policies>
          <inbound>
            <base />
            <validate-azure-ad-token tenant-id="${data.azapi_client_config.this.tenant_id}" header-name="Authorization">
              <audiences>
                <audience>https://cognitiveservices.azure.com</audience>
              </audiences>
              <required-claims>
                <claim name="oid" match="all">
                  <value>${azapi_resource.project.identity[0].principal_id}</value>
                </claim>
              </required-claims>
            </validate-azure-ad-token>
            <authentication-managed-identity resource="https://cognitiveservices.azure.com" />
          </inbound>
          <backend>
            <base />
          </backend>
          <outbound>
            <base />
          </outbound>
          <on-error>
            <base />
          </on-error>
        </policies>
      XML
      , "  ", "\t")), "\n", "\r\n")
    }
  }
  delete_headers = {
    "If-Match" = "*"
  }
  response_export_values = []

  depends_on = [
    azapi_resource.chat_completions,
    azapi_resource.gateway_openai_user,
  ]
}

module "project_connection" {
  source = "../../modules/project-connection"

  name             = var.name
  parent_id        = azapi_resource.project.id
  target           = "${trimsuffix(azapi_resource.gateway.output.properties.gatewayUrl, "/")}/ai/v1"
  audience         = "https://cognitiveservices.azure.com"
  enable_telemetry = var.enable_telemetry
  location         = var.location
  models           = var.models

  depends_on = [
    azapi_resource.gateway_policy,
    azapi_resource.chat_completions,
    azapi_resource.model,
  ]
}
