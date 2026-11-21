mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.CognitiveServices/accounts/aiservices-test"
  enable_telemetry = false
}

# Partner-model deployment (e.g. Anthropic Claude) supplying model_provider_data.
run "partner_model_deployment" {
  command = apply

  variables {
    name = "claude-deployment"
    model = {
      format  = "Anthropic"
      name    = "claude-opus-4-1"
      version = "1"
    }
    scale = {
      type     = "GlobalStandard"
      capacity = 1
    }
    model_provider_data = {
      organization_name = "Contoso"
      country_code      = "US"
      industry          = "Technology"
    }
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.CognitiveServices/accounts/deployments@2026-05-01"
    error_message = "The deployment resource must use the 2026-05-01 API version that supports modelProviderData."
  }

  assert {
    condition     = azapi_resource.this.body.properties.modelProviderData.organizationName == "Contoso"
    error_message = "modelProviderData.organizationName should be mapped from model_provider_data.organization_name."
  }

  assert {
    condition     = azapi_resource.this.body.properties.modelProviderData.countryCode == "US"
    error_message = "modelProviderData.countryCode should be mapped from model_provider_data.country_code."
  }

  assert {
    condition     = azapi_resource.this.body.properties.modelProviderData.industry == "Technology"
    error_message = "modelProviderData.industry should be mapped from model_provider_data.industry."
  }
}

# Backward-compatible OpenAI deployment that does not supply model_provider_data.
run "openai_deployment_without_model_provider_data" {
  command = apply

  variables {
    name = "gpt-deployment"
    model = {
      format  = "OpenAI"
      name    = "gpt-4.1-mini"
      version = "2025-04-14"
    }
    scale = {
      type = "Standard"
    }
  }

  assert {
    condition     = !contains(keys(azapi_resource.this.body.properties), "modelProviderData")
    error_message = "modelProviderData must be omitted from the request body when model_provider_data is not supplied."
  }

  assert {
    condition     = azapi_resource.this.body.properties.model.format == "OpenAI"
    error_message = "Existing OpenAI deployment inputs must continue to work unchanged."
  }

  assert {
    condition     = azapi_resource.this.body.properties.model.name == "gpt-4.1-mini"
    error_message = "Existing OpenAI deployment inputs must continue to work unchanged."
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.CognitiveServices/accounts/deployments@2026-05-01"
    error_message = "The deployment resource must use the 2026-05-01 API version regardless of model_provider_data."
  }
}
