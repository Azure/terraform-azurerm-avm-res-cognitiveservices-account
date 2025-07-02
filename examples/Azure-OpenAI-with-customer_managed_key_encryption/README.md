<!-- BEGIN_TF_DOCS -->
# Default example

This deploys an Azure OpenAI service with a customer managed key.

```hcl
terraform {
  required_version = ">= 1.9, < 2.0"

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
  customer_managed_key = {
    key_vault_resource_id = azurerm_key_vault.this.id
    key_name              = azurerm_key_vault_key.key.name
    user_assigned_identity = {
      resource_id = azurerm_user_assigned_identity.this.id
    }
  }
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = toset([azurerm_user_assigned_identity.this.id])
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_key_vault_key.key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_user_assigned_identity.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [azurerm_client_config.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

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

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->