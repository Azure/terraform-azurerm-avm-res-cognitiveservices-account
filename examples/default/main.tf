terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}


# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  name     = "avm-res-cognitiveservices-account-${module.naming.resource_group.name_unique}"
  location = "West Europe"
}

resource "random_pet" "pet" {}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"

  cognitive_account_kind                = "OpenAI"
  cognitive_account_location            = azurerm_resource_group.this.location
  cognitive_account_name                = "OpenAI-${random_pet.pet.id}"
  cognitive_account_resource_group_name = azurerm_resource_group.this.name
  cognitive_account_sku_name            = "S0"

  cognitive_deployments = {
    "gpt-35-turbo" = {
      name = "gpt-35-turbo"
      model = {
        format  = "OpenAI"
        name    = "gpt-35-turbo"
        version = "0301"
      }
      scale = {
        type = "Standard"
      }
    }
  }
}
