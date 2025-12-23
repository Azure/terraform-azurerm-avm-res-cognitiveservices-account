terraform {
  required_version = ">= 1.9, < 2.0"

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
  version = "0.4.2"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = "avm-res-cognitiveservices-account-${module.naming.resource_group.name_unique}"
}

module "test" {
  source = "../../"

  kind      = "OpenAI"
  location  = azurerm_resource_group.this.location
  name      = "OpenAI-${module.naming.cognitive_account.name_unique}"
  parent_id = azurerm_resource_group.this.id
  sku_name  = "S0"
  cognitive_deployments = {
    "gpt-4o-mini" = {
      name = "gpt-4o-mini"
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
}
