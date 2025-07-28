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

# This example demonstrates the issue with local_auth_enabled = false
# Issue #130: The module fails when trying to list keys on a service with disabled local auth
module "test_openai" {
  source = "../../"

  # Core configuration
  kind                = "OpenAI"
  location            = azurerm_resource_group.this.location
  name                = "OpenAI-${module.naming.cognitive_account.name_unique}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "S0"
  # Disable telemetry for testing
  enable_telemetry   = false
  local_auth_enabled = false
}

# This tests the specific scenario mentioned in issue #130
# AIServices kind with local_auth_enabled = false
module "test_aiservices" {
  source = "../../"

  # Core configuration - THIS IS THE PROBLEMATIC SCENARIO
  kind                = "AIServices"
  location            = azurerm_resource_group.this.location
  name                = "AIServices-${module.naming.cognitive_account.name_unique}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "S0"
  # Disable telemetry for testing
  enable_telemetry   = false
  local_auth_enabled = false
}
