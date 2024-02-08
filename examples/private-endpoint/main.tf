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
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
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

module "vnet" {
  source  = "Azure/subnets/azurerm"
  version = "1.0.0"

  resource_group_name = azurerm_resource_group.this.name
  subnets             = {
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

resource "azurerm_private_dns_zone" "zone" {
  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  name                  = "openai-private-dns-zone"
  private_dns_zone_name = azurerm_private_dns_zone.zone.name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = module.vnet.vnet_id
}

resource "random_pet" "pet" {}

data "azurerm_client_config" "this" {}

resource "azurerm_key_vault" "this" {
  name                       = "zjhecogkv${replace(random_pet.pet.id, "-", "")}"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.this.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.this.tenant_id
    object_id = data.azurerm_client_config.this.object_id

    key_permissions = [
      "Create",
      "Delete",
      "Get",
      "Purge",
      "Recover",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]
  }
  access_policy {
    tenant_id = data.azurerm_client_config.this.tenant_id
    object_id = azurerm_user_assigned_identity.this.principal_id

    key_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uai-zjhe-cog"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_key_vault_key" "key" {
  name         = "generated-certificate"
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"

  kind                = "OpenAI"
  location            = azurerm_resource_group.this.location
  name                = "OpenAI-${random_pet.pet.id}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "S0"

  cognitive_deployments = {
    "gpt-4-32k" = {
      name  = "gpt-4-32k"
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
  private_endpoints = {
    pe_endpoint = {
      name                            = "pe_endpoint"
      private_dns_zone_resource_ids   = toset([azurerm_private_dns_zone.zone.id])
      private_service_connection_name = "pe_endpoint_connection"
      subnet_resource_id              = module.vnet.vnet_subnets_name_id["subnet0"]
    }
    pe_endpoint2 = {
      name                            = "pe_endpoint2"
      private_dns_zone_resource_ids   = toset([azurerm_private_dns_zone.zone.id])
      private_service_connection_name = "pe_endpoint_connection2"
      subnet_resource_id              = module.vnet.vnet_subnets_name_id["subnet0"]
    }
  }
  customer_managed_key = {
    key_vault_resource_id = azurerm_key_vault.this.id
    key_name = azurerm_key_vault_key.key.name
    user_assigned_identity_resource_id = azurerm_user_assigned_identity.this.id
  }
}
