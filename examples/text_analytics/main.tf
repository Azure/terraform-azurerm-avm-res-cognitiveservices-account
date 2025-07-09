terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # time = {
    #   source  = "hashicorp/time"
    #   version = "0.12.1"
    # }
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
  location = var.location
  name     = "avm-res-cognitiveservices-account-${module.naming.resource_group.name_unique}"
}

resource "random_string" "suffix" {
  length  = 10
  numeric = false
  special = false
  upper   = false
}

resource "azurerm_search_service" "this" {
  name                = "ass-test${random_string.suffix.result}0"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "standard"
}

resource "time_sleep" "ten" {
  create_duration = "10s"
  depends_on = [
    azurerm_search_service.this
  ]
}

resource "azurerm_search_service" "this2" {
  name                = "ass-test${random_string.suffix.result}1"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "standard"
  depends_on = [
    time_sleep.ten
  ]
}


module "test" {
  # source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  # version = "0.7.1"
  source = "../../"

  kind                = "TextAnalytics"
  location            = azurerm_resource_group.this.location
  name                = "TextAnalytics-${module.naming.cognitive_account.name_unique}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "S"
  custom_question_answering_search_service_id = azurerm_search_service.this2.id
  sensitive_data = {
    custom_question_answering_search_service_key = azurerm_search_service.this2.primary_key
  }
  # custom_question_answering_search_service_key = azurerm_search_service.this.primary_key

  enable_telemetry = false
}
