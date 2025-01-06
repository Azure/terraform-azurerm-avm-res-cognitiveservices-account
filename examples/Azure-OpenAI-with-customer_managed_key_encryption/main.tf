terraform {
  required_version = ">= 1.3.0"
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

resource "random_string" "suffix" {
  length  = 5
  numeric = false
  special = false
  upper   = false
}

data "azurerm_client_config" "this" {}

resource "azurerm_key_vault" "this" {
  location                   = azurerm_resource_group.this.location
  name                       = "zjhecogkv${replace(random_string.suffix.result, "-", "")}"
  resource_group_name        = azurerm_resource_group.this.name
  sku_name                   = "premium"
  tenant_id                  = data.azurerm_client_config.this.tenant_id
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  access_policy {
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
    object_id = data.azurerm_client_config.this.object_id
    tenant_id = data.azurerm_client_config.this.tenant_id
  }
  access_policy {
    certificate_permissions = [
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "Purge",
      "Update"
    ]
    key_permissions = [
      "Get",
      "Create",
      "List",
      "Restore",
      "Recover",
      "UnwrapKey",
      "WrapKey",
      "Purge",
      "Encrypt",
      "Decrypt",
      "Sign",
      "Verify",
    ]
    object_id = azurerm_user_assigned_identity.this.principal_id
    secret_permissions = [
      "Get",
    ]
    tenant_id = data.azurerm_client_config.this.tenant_id
  }
}

resource "azurerm_key_vault_certificate" "cert" {
  count = 3

  key_vault_id = azurerm_key_vault.this.id
  name         = "cognitiveservices${count.index}"

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }
    key_properties {
      exportable = true
      key_type   = "RSA"
      reuse_key  = true
      key_size   = 2048
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    lifetime_action {
      action {
        action_type = "AutoRenew"
      }
      trigger {
        days_before_expiry = 30
      }
    }
    x509_certificate_properties {
      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]
      subject            = "CN=hello-world"
      validity_in_months = 12
      extended_key_usage = []
    }
  }
}

resource "azurerm_key_vault_managed_hardware_security_module" "this" {
  admin_object_ids                          = [data.azurerm_client_config.this.object_id]
  location                                  = azurerm_resource_group.this.location
  name                                      = "hsm${random_string.suffix.result}"
  resource_group_name                       = azurerm_resource_group.this.name
  sku_name                                  = "Standard_B1"
  tenant_id                                 = data.azurerm_client_config.this.tenant_id
  purge_protection_enabled                  = false
  security_domain_key_vault_certificate_ids = [for cert in azurerm_key_vault_certificate.cert : cert.id]
  security_domain_quorum                    = 3
}

resource "azurerm_key_vault_managed_hardware_security_module_role_assignment" "this" {
  name               = "1e243909-064c-6ac3-84e9-1c8bf8d6ad22"
  principal_id       = data.azurerm_client_config.this.object_id
  role_definition_id = "/Microsoft.KeyVault/providers/Microsoft.Authorization/roleDefinitions/21dbd100-6940-42c2-9190-5d6cb909625b"
  scope              = "/keys"
  managed_hsm_id     = azurerm_key_vault_managed_hardware_security_module.this.id
}

resource "azurerm_key_vault_managed_hardware_security_module_role_assignment" "this1" {
  name               = "1e243909-064c-6ac3-84e9-1c8bf8d6ad23"
  principal_id       = data.azurerm_client_config.this.object_id
  role_definition_id = "/Microsoft.KeyVault/providers/Microsoft.Authorization/roleDefinitions/515eb02d-2335-4d2d-92f2-b1cbdf9c3778"
  scope              = "/keys"
  managed_hsm_id     = azurerm_key_vault_managed_hardware_security_module.this.id
}

resource "azurerm_key_vault_managed_hardware_security_module_key" "this" {
  key_opts       = ["sign"]
  key_type       = "EC-HSM"
  managed_hsm_id = azurerm_key_vault_managed_hardware_security_module.this.id
  name           = "hsmkey"
  curve          = "P-521"

  depends_on = [
    azurerm_key_vault_managed_hardware_security_module_role_assignment.this,
    azurerm_key_vault_managed_hardware_security_module_role_assignment.this1,
  ]
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uai-zjhe-cog"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_key_vault_key" "key" {
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
  key_type     = "RSA"
  key_vault_id = azurerm_key_vault.this.id
  name         = "generated-certificate"
  key_size     = 2048

  rotation_policy {
    expire_after         = "P90D"
    notify_before_expiry = "P29D"

    automatic {
      time_before_expiry = "P30D"
    }
  }
}

module "test" {
  source = "../../"

  kind                = "Face"
  location            = azurerm_resource_group.this.location
  name                = "Face-${module.naming.cognitive_account.name_unique}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "E0"

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = toset([azurerm_user_assigned_identity.this.id])
  }
  customer_managed_key = {
    key_vault_resource_id = azurerm_key_vault.this.id
    key_name              = azurerm_key_vault_key.key.name
    user_assigned_identity = {
      resource_id = azurerm_user_assigned_identity.this.id
    }
  }
}

module "test_hsm_key" {
  source = "../../"

  kind                = "Face"
  location            = azurerm_resource_group.this.location
  name                = "Face-hsm-${module.naming.cognitive_account.name_unique}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "E0"

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = toset([azurerm_user_assigned_identity.this.id])
  }
  is_hsm_key = true
  customer_managed_key = {
    key_vault_resource_id = azurerm_key_vault_managed_hardware_security_module.this.id
    key_name              = azurerm_key_vault_managed_hardware_security_module_key.this.name
    user_assigned_identity = {
      resource_id = azurerm_user_assigned_identity.this.id
    }
  }
}
