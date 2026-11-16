terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
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
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.2.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "westus"
  name     = "avm-res-aiservice-${module.naming.resource_group.name_unique}"
}

resource "random_string" "suffix" {
  length  = 15
  numeric = false
  special = false
  upper   = false
}

data "azurerm_client_config" "this" {}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uai-aiservice"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_application_insights" "this" {
  application_type    = "web"
  location            = azurerm_resource_group.this.location
  name                = "appInsights-${module.naming.application_insights.name_unique}"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_key_vault" "this2" {
  location                 = azurerm_resource_group.this.location
  name                     = "kv2${replace(random_string.suffix.result, "-", "")}"
  resource_group_name      = azurerm_resource_group.this.name
  sku_name                 = "standard"
  tenant_id                = data.azurerm_client_config.this.tenant_id
  purge_protection_enabled = true
}

resource "azurerm_key_vault_access_policy" "this" {
  key_vault_id = azurerm_key_vault.this2.id
  object_id    = data.azurerm_client_config.this.object_id
  tenant_id    = data.azurerm_client_config.this.tenant_id
  key_permissions = [
    "Create",
    "Get",
    "Delete",
    "Purge",
    "GetRotationPolicy",
  ]
}

resource "azurerm_storage_account" "this" {
  account_replication_type = "GRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.this.location
  name                     = "sa${replace(random_string.suffix.result, "-", "")}"
  resource_group_name      = azurerm_resource_group.this.name
}

resource "azurerm_machine_learning_workspace" "this" {
  application_insights_id = azurerm_application_insights.this.id
  key_vault_id            = azurerm_key_vault.this2.id
  location                = azurerm_resource_group.this.location
  name                    = "AMLW-${module.naming.machine_learning_workspace.name_unique}"
  resource_group_name     = azurerm_resource_group.this.name
  storage_account_id      = azurerm_storage_account.this.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azapi_update_resource" "allow_ai_managed_vnet_preview" {
  resource_id = "/subscriptions/${data.azurerm_client_config.this.subscription_id}/providers/Microsoft.Features/featureProviders/Microsoft.CognitiveServices/subscriptionFeatureRegistrations/AI.ManagedVnetPreview"
  type        = "Microsoft.Features/featureProviders/subscriptionFeatureRegistrations@2021-07-01"
  body = {
    properties = {}
  }
}

module "test" {
  source = "../../"

  kind      = "AIServices"
  location  = azurerm_resource_group.this.location
  name      = "AIService-${module.naming.cognitive_account.name_unique}"
  parent_id = azurerm_resource_group.this.id
  sku_name  = "S0"
  aml_workspace = {
    resource_id        = azurerm_machine_learning_workspace.this.id
    identity_client_id = azurerm_machine_learning_workspace.this.identity[0].principal_id
  }
  enable_telemetry   = var.enable_telemetry
  local_auth_enabled = true
  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = toset([azurerm_user_assigned_identity.this.id])
  }

  depends_on = [
    azapi_update_resource.allow_ai_managed_vnet_preview,
  ]
}
