terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
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
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "East US"
  name     = "avm-res-cognitiveservices-account-${module.naming.resource_group.name_unique}"
}

module "test" {
  source = "../../"

  kind                = "OpenAI"
  location            = azurerm_resource_group.this.location
  name                = "OpenAI-${module.naming.cognitive_account.name_unique}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "S0"

  cognitive_deployments = {
    "gpt-4-32k" = {
      name = "gpt-4-32k"
      model = {
        format  = "OpenAI"
        name    = "gpt-4-32k"
        version = "0613"
      }
      scale = {
        type = "Standard"
      }
    }
  }
}