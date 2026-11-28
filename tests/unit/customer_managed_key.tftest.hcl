mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.CognitiveServices/accounts/unit-account"
      output = {}
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {}


mock_provider "random" {
  mock_resource "random_string" {
    defaults = {
      result = "abcde"
    }
  }
}

mock_provider "time" {}

override_data {
  target = data.azapi_resource.customer_managed_key
  values = {
    output = {
      key_uri_with_version = "https://kv-unit.vault.azure.net/keys/cmk/0123456789abcdef0123456789abcdef"
    }
  }
}

override_data {
  target = data.azapi_resource.managed_hsm_key
  values = {
    output = {
      key_uri_with_version = "https://hsm-unit.managedhsm.azure.net/keys/cmk/fedcba9876543210fedcba9876543210"
    }
  }
}

override_data {
  target = data.azapi_resource.customer_managed_key_identity
  values = {
    output = {
      client_id = "11111111-1111-1111-1111-111111111111"
    }
  }
}

variables {
  enable_telemetry   = false
  kind               = "OpenAI"
  local_auth_enabled = false
  location           = "eastus"
  name               = "unit-account"
  parent_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit"
  sku_name           = "S0"
}

run "key_vault_key_is_patched_onto_the_account" {
  command = apply

  variables {
    managed_identities = {
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai"]
    }
    customer_managed_key = {
      key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.KeyVault/vaults/kv-unit"
      key_name              = "cmk"
      user_assigned_identity = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai"
      }
    }
  }

  assert {
    condition     = data.azapi_resource.customer_managed_key[0].resource_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.KeyVault/vaults/kv-unit/keys/cmk"
    error_message = "The key MUST be read from the key vault named in customer_managed_key."
  }

  assert {
    condition     = azapi_resource_action.customer_managed_key[0].method == "PATCH" && azapi_resource_action.customer_managed_key[0].resource_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.CognitiveServices/accounts/unit-account"
    error_message = "The key MUST be set with a PATCH on the account."
  }

  assert {
    condition = azapi_resource_action.customer_managed_key[0].body.properties.encryption == {
      keySource = "Microsoft.KeyVault"
      keyVaultProperties = {
        identityClientId = "11111111-1111-1111-1111-111111111111"
        keyName          = "cmk"
        keyVaultUri      = "https://kv-unit.vault.azure.net/"
        keyVersion       = "0123456789abcdef0123456789abcdef"
      }
    }
    error_message = "The encryption body MUST carry the vault URI, key name, latest key version and identity client ID."
  }

  assert {
    condition     = azapi_resource_action.customer_managed_key_removal[0].when == "destroy" && azapi_resource_action.customer_managed_key_removal[0].body.properties.encryption.keySource == "Microsoft.CognitiveServices"
    error_message = "Removing the key MUST switch the account back to Microsoft-managed keys."
  }

  assert {
    condition     = output.resource.customer_managed_key[0].key_vault_key_id == "https://kv-unit.vault.azure.net/keys/cmk/0123456789abcdef0123456789abcdef"
    error_message = "The resource output MUST report the versioned key ID."
  }
}

run "hsm_key_is_set_on_ai_services" {
  command = apply

  variables {
    kind = "AIServices"
    customer_managed_key = {
      key_vault_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.KeyVault/managedHSMs/hsm-unit"
      key_name              = "cmk"
    }
    is_hsm_key = true
  }

  assert {
    condition = azapi_update_resource.ai_service_hsm_key[0].body.properties.encryption == {
      keySource = "Microsoft.KeyVault"
      keyVaultProperties = {
        identityClientId = null
        keyName          = "cmk"
        keyVaultUri      = "https://hsm-unit.managedhsm.azure.net/"
        keyVersion       = "fedcba9876543210fedcba9876543210"
      }
    }
    error_message = "The HSM encryption body MUST carry the HSM URI, key name and latest key version."
  }

  assert {
    condition     = length(azapi_resource_action.customer_managed_key) == 0 && length(azapi_resource_action.customer_managed_key_removal) == 0
    error_message = "HSM keys MUST NOT use the key vault actions."
  }

  assert {
    condition     = output.resource.customer_managed_key[0].managed_hsm_key_id == "https://hsm-unit.managedhsm.azure.net/keys/cmk/fedcba9876543210fedcba9876543210"
    error_message = "The resource output MUST report the versioned HSM key ID."
  }
}

run "no_customer_managed_key_by_default" {
  command = plan

  assert {
    condition     = length(azapi_resource_action.customer_managed_key) == 0 && length(azapi_resource_action.customer_managed_key_removal) == 0 && length(data.azapi_resource.customer_managed_key) == 0
    error_message = "Nothing MUST be planned for the key when customer_managed_key is null."
  }
}
