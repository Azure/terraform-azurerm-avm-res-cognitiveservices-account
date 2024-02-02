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
  location = "West Europe"
  name     = "avm-res-cognitiveservices-account-${module.naming.resource_group.name_unique}"
}

module "vnet" {
  source  = "Azure/subnets/azurerm"
  version = "1.0.0"

  resource_group_name = azurerm_resource_group.this.name
  subnets = {
    subnet0 = {
      address_prefixes  = ["10.52.0.0/24"]
      service_endpoints = ["Microsoft.CognitiveServices"]
    }
    subnet1 = {
      address_prefixes  = ["10.52.1.0/24"]
      service_endpoints = ["Microsoft.CognitiveServices"]
    }
  }
  virtual_network_address_space = ["10.52.0.0/16"]
  virtual_network_location      = azurerm_resource_group.this.location
  virtual_network_name          = "vnet"
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

  private_endpoint_subnets = {
    vnet = {
      vnet_id = module.vnet.vnet_id
      subnets = {
        subnet0 = {
          id = module.vnet.vnet_subnets_name_id["subnet0"]
        }
      }
    }
  }

  private_endpoint = {
    pe_endpoint = {
      name                            = "pe_endpoint"
      private_dns_entry_enabled       = true
      dns_zone_virtual_network_link   = "dns_zone_link"
      is_manual_connection            = false
      private_service_connection_name = "pe_endpoint_connection"
      vnet_key                        = "vnet"
      subnet_key                      = "subnet0"
    }
    pe_endpoint2 = {
      name                            = "pe_endpoint2"
      private_dns_entry_enabled       = true
      dns_zone_virtual_network_link   = "dns_zone_link2"
      is_manual_connection            = false
      private_service_connection_name = "pe_endpoint_connection2"
      vnet_key                        = "vnet"
      subnet_key                      = "subnet0"
    }
  }
  green_field_private_dns_zone = {
    resource_group_name = azurerm_resource_group.this.name
  }
}
