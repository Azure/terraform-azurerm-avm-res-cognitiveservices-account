<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0, < 4.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="provider_random"></a> [random](#provider\_random) (>= 3.5.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_pet.pet](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: >= 0.3.0

### <a name="module_test"></a> [test](#module\_test)

Source: ../../

Version:

### <a name="module_vnet"></a> [vnet](#module\_vnet)

Source: Azure/subnets/azurerm

Version: 1.0.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->