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
  subscription_id = "ef569087-2c0a-4b48-b649-a76367a5f60d"
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
  name     = "avm-res-aiservice-${module.naming.resource_group.name_unique}"
}

resource "random_string" "suffix" {
  length  = 5
  numeric = false
  special = false
  upper   = false
}

data "azurerm_client_config" "this" {}

# resource "azurerm_key_vault" "this" {
#   location                   = azurerm_resource_group.this.location
#   name                       = "suchiai${replace(random_string.suffix.result, "-", "")}"
#   resource_group_name        = azurerm_resource_group.this.name
#   sku_name                   = "premium"
#   tenant_id                  = data.azurerm_client_config.this.tenant_id
#   purge_protection_enabled   = true
#   soft_delete_retention_days = 7

#   access_policy {
#     key_permissions = [
#       "Create",
#       "Delete",
#       "Get",
#       "Purge",
#       "Recover",
#       "Update",
#       "GetRotationPolicy",
#       "SetRotationPolicy"
#     ]
#     object_id = data.azurerm_client_config.this.object_id
#     tenant_id = data.azurerm_client_config.this.tenant_id
#   }
#   access_policy {
#     key_permissions = [
#       "Get",
#       "Create",
#       "List",
#       "Restore",
#       "Recover",
#       "UnwrapKey",
#       "WrapKey",
#       "Purge",
#       "Encrypt",
#       "Decrypt",
#       "Sign",
#       "Verify",
#     ]
#     object_id = azurerm_user_assigned_identity.this.principal_id
#     secret_permissions = [
#       "Get",
#     ]
#     tenant_id = data.azurerm_client_config.this.tenant_id
#   }
# }

# resource "azurerm_key_vault_managed_hardware_security_module" "this" {
#   name                       = "blableh${replace(random_string.suffix.result, "-", "")}"
#   resource_group_name        = azurerm_resource_group.this.name
#   location                   = azurerm_resource_group.this.location
#   sku_name                   = "Standard_B1"
#   purge_protection_enabled   = false
#   soft_delete_retention_days = 90
#   tenant_id                  = data.azurerm_client_config.this.tenant_id
#   admin_object_ids           = [data.azurerm_client_config.this.object_id]
# }

resource "azurerm_key_vault" "this" {
  location                   = azurerm_resource_group.this.location
  name                       = "aisuchi${replace(random_string.suffix.result, "-", "")}"
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
    certificate_permissions = [
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "Purge",
      "Update"
    ]
    secret_permissions = [
      "Delete",
      "Get",
      "Set",
    ]
    object_id = data.azurerm_client_config.this.object_id
    tenant_id = data.azurerm_client_config.this.tenant_id
  }
  access_policy {
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
      "Delete",
      "Get",
      "Set",
    ]
    tenant_id = data.azurerm_client_config.this.tenant_id
  }
}

resource "azurerm_key_vault_certificate" "cert" {
  count        = 3
  name         = "acchsmcert${count.index}"
  key_vault_id = azurerm_key_vault.this.id
  certificate_policy {
    issuer_parameters {
      name = "Self"
    }
    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }
    lifetime_action {
      action {
        action_type = "AutoRenew"
      }
      trigger {
        days_before_expiry = 30
      }
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    x509_certificate_properties {
      extended_key_usage = []
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
    }
  }
}

resource "azurerm_key_vault_managed_hardware_security_module" "this" {
  name                                      = "sdjhkremi${replace(random_string.suffix.result, "-", "")}"
  resource_group_name                       = azurerm_resource_group.this.name
  location                                  = azurerm_resource_group.this.location
  sku_name                                  = "Standard_B1"
  purge_protection_enabled                  = false
  soft_delete_retention_days                = 90
  tenant_id                                 = data.azurerm_client_config.this.tenant_id
  admin_object_ids                          = [data.azurerm_client_config.this.object_id]
  security_domain_key_vault_certificate_ids = [for cert in azurerm_key_vault_certificate.cert : cert.id]
  security_domain_quorum                    = 2
}

resource "time_sleep" "this" {
  create_duration = "100s"
  depends_on      = [azurerm_key_vault_managed_hardware_security_module.this]
}

// this gives your service principal the HSM Crypto User role which lets you create and destroy hsm keys
resource "azurerm_key_vault_managed_hardware_security_module_role_assignment" "hsm-crypto-user" {
  managed_hsm_id     = azurerm_key_vault_managed_hardware_security_module.this.id
  name               = "1e243909-064c-6ac3-84e9-1c8bf8d6ad22"
  scope              = "/keys"
  role_definition_id = "/Microsoft.KeyVault/providers/Microsoft.Authorization/roleDefinitions/21dbd100-6940-42c2-9190-5d6cb909625b"
  principal_id       = data.azurerm_client_config.this.object_id
  depends_on         = [time_sleep.this]
}

// this gives your service principal the HSM Crypto Officer role which lets you purge hsm keys
resource "azurerm_key_vault_managed_hardware_security_module_role_assignment" "hsm-crypto-officer" {
  managed_hsm_id     = azurerm_key_vault_managed_hardware_security_module.this.id
  name               = "1e243909-064c-6ac3-84e9-1c8bf8d6ad23"
  scope              = "/keys"
  role_definition_id = "/Microsoft.KeyVault/providers/Microsoft.Authorization/roleDefinitions/515eb02d-2335-4d2d-92f2-b1cbdf9c3778"
  principal_id       = data.azurerm_client_config.this.object_id
  depends_on         = [time_sleep.this]
}

resource "azurerm_key_vault_managed_hardware_security_module_key" "this" {
  name           = "hsmkeysuchi"
  managed_hsm_id = azurerm_key_vault_managed_hardware_security_module.this.id
  key_type       = "EC-HSM"
  curve          = "P-521"
  key_opts       = ["sign"]

  depends_on = [
    azurerm_key_vault_managed_hardware_security_module_role_assignment.hsm-crypto-user,
    azurerm_key_vault_managed_hardware_security_module_role_assignment.hsm-crypto-officer
  ]
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uai-such-aiservice"
  resource_group_name = azurerm_resource_group.this.name
}

# resource "azurerm_key_vault_key" "this" {
#   key_opts = [
#     "decrypt",
#     "encrypt",
#     "sign",
#     "unwrapKey",
#     "verify",
#     "wrapKey",
#   ]
#   key_type     = "RSA-HSM"
#   key_vault_id = azurerm_key_vault.this.id
#   name         = "suchi-ai-certificate"
#   key_size     = 2048

#   rotation_policy {
#     expire_after         = "P90D"
#     notify_before_expiry = "P29D"

#     automatic {
#       time_before_expiry = "P30D"
#     }
#   }
# }

module "test" {
  source              = "../../"
  kind                = "AIServices"
  location            = azurerm_resource_group.this.location
  name                = "AIService-${module.naming.cognitive_account.name_unique}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "S0"
  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = toset([azurerm_user_assigned_identity.this.id])
  }
  customer_managed_key = {
    # key_vault_resource_id = azurerm_key_vault.this.id
    key_vault_resource_id = azurerm_key_vault_managed_hardware_security_module.this.id
    # key_name = azurerm_key_vault_key.this.name
    key_name = azurerm_key_vault_managed_hardware_security_module_key.this.name
    user_assigned_identity = {
      resource_id = azurerm_user_assigned_identity.this.id
    }
  }
  depends_on = [azurerm_key_vault_managed_hardware_security_module.this, azurerm_key_vault_managed_hardware_security_module_key.this, azurerm_key_vault_managed_hardware_security_module_role_assignment.hsm-crypto-officer, azurerm_key_vault_managed_hardware_security_module_role_assignment.hsm-crypto-user]
}