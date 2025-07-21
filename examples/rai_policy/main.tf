terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}


# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = "avm-res-cognitiveservices-account-rai-${module.naming.resource_group.name_unique}"
}

resource "random_pet" "pet" {}

module "test" {
  source = "../../"

  kind                = "OpenAI"
  location            = azurerm_resource_group.this.location
  name                = "OpenAI-${random_pet.pet.id}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "S0"
  cognitive_deployments = {
    "gpt-4o-mini" = {
      name            = "gpt-4o-mini"
      rai_policy_name = "policy0"
      model = {
        format  = "OpenAI"
        name    = "gpt-4o-mini"
        version = "2024-07-18"
      }
      scale = {
        type = "Standard"
      }
    }
  }
  enable_telemetry = false
  rai_policies = {
    policy1 = {
      name             = "policy0"
      base_policy_name = "Microsoft.Default"
      mode             = "Asynchronous_filter"
      content_filters = [{
        name               = "Hate"
        blocking           = true
        enabled            = true
        severity_threshold = "High"
        source             = "Prompt"
      }]
    }
  }
}
