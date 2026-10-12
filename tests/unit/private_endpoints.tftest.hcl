mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/privateEndpoints/mocked"
      name   = "provider-generated-name"
      output = {}
      tags   = { provider_default = "unset" }
    }
  }

  mock_data "azapi_resource" {
    defaults = {
      exists = false
      output = { properties = {} }
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [{
          id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
          role_name = "Reader"
        }]
      }
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

mock_provider "modtm" {}

mock_provider "random" {
  mock_resource "random_uuid" {
    defaults = {
      result = "11111111-1111-4111-8111-111111111111"
    }
  }

  mock_resource "random_string" {
    defaults = {
      result = "abcde"
    }
  }
}

mock_provider "time" {}

override_resource {
  target = azapi_resource.this[0]
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.CognitiveServices/accounts/unit-account"
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
  tags               = { account_only = "not-inherited" }
}

run "omitted_endpoints" {
  command = apply

  assert {
    condition = (
      length(output.private_endpoints) == 0 &&
      length(azapi_resource.private_endpoints_unmanaged) == 0 &&
      length(azapi_resource.private_dns_zone_groups) == 0 &&
      length(azapi_resource.private_endpoint_role_assignments) == 0 &&
      length(azapi_resource.private_endpoint_locks) == 0
    )
    error_message = "Omitted private endpoints must not create endpoints or extension resources."
  }
}

run "null_endpoints" {
  command = apply

  variables {
    private_endpoints = null
  }

  assert {
    condition     = length(output.private_endpoints) == 0
    error_message = "A null endpoint map must retain the empty-map default."
  }
}

run "omitted_fields" {
  command = apply

  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/unit/subnets/endpoints"
        role_assignments = {
          reader = {
            principal_id               = "33333333-3333-4333-8333-333333333333"
            role_definition_id_or_name = "Reader"
          }
        }
        lock = { kind = "CanNotDelete" }
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.4"
          }
        }
      }
    }
  }

  assert {
    condition = (
      azapi_resource.private_endpoints["endpoint"].name == "pep-account-${uuidv5("url", output.resource_id)}" &&
      azapi_resource.private_endpoints["endpoint"].body.properties.customNetworkInterfaceName == "nic-pep-account-${uuidv5("url", output.resource_id)}" &&
      azapi_resource.private_endpoints["endpoint"].body.properties.privateLinkServiceConnections[0].name == "pcon-pep-account-${uuidv5("url", output.resource_id)}"
    )
    error_message = "Default endpoint, NIC and connection names must remain identical to utility 0.6.0."
  }

  assert {
    condition = (
      azapi_resource.private_endpoints["endpoint"].type == "Microsoft.Network/privateEndpoints@2024-05-01" &&
      azapi_resource.private_endpoints["endpoint"].parent_id == var.parent_id &&
      azapi_resource.private_endpoints["endpoint"].location == var.location &&
      data.azapi_resource.existing_private_endpoints["endpoint"].name == "pep-unit-account" &&
      data.azapi_resource.existing_private_endpoints["endpoint"].parent_id == var.parent_id &&
      azapi_resource.private_endpoints["endpoint"].body.properties.privateLinkServiceConnections[0].properties.privateLinkServiceId == output.resource_id &&
      azapi_resource.private_endpoints["endpoint"].body.properties.privateLinkServiceConnections[0].properties.groupIds[0] == "account" &&
      azapi_resource.private_endpoints["endpoint"].body.properties.ipConfigurations[0].properties.groupId == "account" &&
      azapi_resource.private_endpoints["endpoint"].body.properties.ipConfigurations[0].properties.memberName == "default" &&
      azapi_resource.private_endpoints["endpoint"].body.properties.ipConfigurations[0].properties.privateIPAddress == "10.0.0.4"
    )
    error_message = "Omitted fields must retain the existing API, lookup, parent, location and static IP defaults."
  }

  assert {
    condition = (
      azapi_resource.private_endpoint_role_assignments["endpoint-reader"].name == "11111111-1111-4111-8111-111111111111" &&
      azapi_resource.private_endpoint_role_assignments["endpoint-reader"].type == "Microsoft.Authorization/roleAssignments@2022-04-01" &&
      azapi_resource.private_endpoint_role_assignments["endpoint-reader"].parent_id == azapi_resource.private_endpoints["endpoint"].id &&
      azapi_resource.private_endpoint_role_assignments["endpoint-reader"].body.properties.principalType == null &&
      azapi_resource.private_endpoint_locks["endpoint"].type == "Microsoft.Authorization/locks@2020-05-01" &&
      azapi_resource.private_endpoint_locks["endpoint"].parent_id == azapi_resource.private_endpoints["endpoint"].id &&
      jsonencode(azapi_resource.private_endpoint_locks["endpoint"].body) == jsonencode({ properties = { level = "CanNotDelete" } }) &&
      module.private_endpoint_interfaces.lock_private_endpoint_azapi["endpoint"].name == null
    )
    error_message = "Omitted role names and lock notes must preserve the existing names, APIs, parents and body."
  }

  assert {
    condition = (
      azapi_resource.private_dns_zone_groups["endpoint"].type == "Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01" &&
      azapi_resource.private_dns_zone_groups["endpoint"].name == "default" &&
      length(azapi_resource.private_dns_zone_groups["endpoint"].body.properties.privateDnsZoneConfigs) == 0 &&
      length(azapi_resource.private_endpoints["endpoint"].body.properties.applicationSecurityGroups) == 0 &&
      azapi_resource.private_endpoints["endpoint"].tags == tomap({ provider_default = "unset" })
    )
    error_message = "Empty collections and omitted tags must not gain associations or inherit account tags."
  }
}

run "null_fields" {
  command = apply

  variables {
    private_endpoints = {
      endpoint = {
        name                                    = null
        subnet_resource_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/unit/subnets/endpoints"
        subresource_name                        = null
        location                                = null
        resource_group_name                     = null
        network_interface_name                  = null
        private_service_connection_name         = null
        private_dns_zone_group_name             = null
        private_dns_zone_resource_ids           = null
        application_security_group_associations = null
        tags                                    = null
        role_assignments = {
          reader = {
            name                                   = null
            principal_id                           = "33333333-3333-4333-8333-333333333333"
            role_definition_id_or_name             = "Reader"
            description                            = null
            skip_service_principal_aad_check       = null
            condition                              = null
            condition_version                      = null
            delegated_managed_identity_resource_id = null
            principal_type                         = null
          }
        }
        lock = {
          kind  = "CanNotDelete"
          name  = null
          notes = null
        }
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.4"
            member_name        = null
          }
        }
      }
    }
  }

  assert {
    condition = (
      jsonencode(output.private_endpoints["endpoint"].body) == jsonencode(run.omitted_fields.private_endpoints["endpoint"].body) &&
      output.private_endpoints["endpoint"].name == run.omitted_fields.private_endpoints["endpoint"].name &&
      output.private_endpoints["endpoint"].tags == run.omitted_fields.private_endpoints["endpoint"].tags &&
      output.private_endpoints["endpoint"].location == var.location &&
      output.private_endpoints["endpoint"].parent_id == var.parent_id &&
      azapi_resource.private_endpoint_role_assignments["endpoint-reader"].name == "11111111-1111-4111-8111-111111111111" &&
      jsonencode(azapi_resource.private_endpoint_locks["endpoint"].body) == jsonencode({ properties = { level = "CanNotDelete" } })
    )
    error_message = "Explicit null fields must produce the same endpoint and extension configuration as omission."
  }
}

run "explicit_fields_managed_dns" {
  command = apply

  variables {
    private_endpoints = {
      explicit = {
        name                                    = "pe-explicit"
        subnet_resource_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/unit/subnets/endpoints"
        subresource_name                        = "custom-group"
        location                                = "westeurope"
        resource_group_name                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-endpoints"
        network_interface_name                  = "nic-explicit"
        private_service_connection_name         = "connection-explicit"
        private_dns_zone_group_name             = "zones-explicit"
        private_dns_zone_resource_ids           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com"]
        application_security_group_associations = { web = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/applicationSecurityGroups/web" }
        tags                                    = { endpoint_only = "managed" }
        role_assignments = {
          reader = {
            name                                   = "22222222-2222-4222-8222-222222222222"
            principal_id                           = "33333333-3333-4333-8333-333333333333"
            role_definition_id_or_name             = "Reader"
            description                            = "Endpoint reader"
            skip_service_principal_aad_check       = true
            condition                              = "((!(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'})))"
            condition_version                      = "2.0"
            delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.ManagedIdentity/userAssignedIdentities/delegated"
            principal_type                         = "Group"
          }
        }
        lock = {
          kind  = "ReadOnly"
          name  = "lock-explicit"
          notes = "Explicit endpoint lock"
        }
        ip_configurations = {
          primary = {
            name               = "ip-explicit"
            private_ip_address = "10.0.0.5"
            member_name        = "member-explicit"
          }
        }
      }
    }
  }

  override_data {
    target = data.azapi_resource.existing_private_endpoints["explicit"]
    values = {
      exists = true
      output = { properties = { customNetworkInterfaceName = "old-nic" } }
    }
  }

  assert {
    condition = (
      azapi_resource.private_endpoints["explicit"].name == "pe-explicit" &&
      azapi_resource.private_endpoints["explicit"].location == "westeurope" &&
      azapi_resource.private_endpoints["explicit"].parent_id == var.private_endpoints["explicit"].resource_group_name &&
      data.azapi_resource.existing_private_endpoints["explicit"].parent_id == var.private_endpoints["explicit"].resource_group_name &&
      azapi_resource.private_endpoints["explicit"].body.properties.customNetworkInterfaceName == "nic-explicit" &&
      azapi_resource.private_endpoints["explicit"].body.properties.privateLinkServiceConnections[0].name == "connection-explicit" &&
      azapi_resource.private_endpoints["explicit"].body.properties.privateLinkServiceConnections[0].properties.groupIds[0] == "custom-group" &&
      azapi_resource.private_endpoints["explicit"].body.properties.ipConfigurations[0].name == "ip-explicit" &&
      azapi_resource.private_endpoints["explicit"].body.properties.ipConfigurations[0].properties.groupId == "custom-group" &&
      azapi_resource.private_endpoints["explicit"].body.properties.ipConfigurations[0].properties.memberName == "member-explicit" &&
      azapi_resource.private_endpoints["explicit"].body.properties.ipConfigurations[0].properties.privateIPAddress == "10.0.0.5" &&
      azapi_resource.private_endpoints["explicit"].tags == tomap({ endpoint_only = "managed" })
    )
    error_message = "Every explicit endpoint field must reach the managed resource; an explicit NIC must beat discovery."
  }

  assert {
    condition = (
      azapi_resource.private_endpoint_role_assignments["explicit-reader"].name == "22222222-2222-4222-8222-222222222222" &&
      jsonencode(azapi_resource.private_endpoint_role_assignments["explicit-reader"].body.properties) == jsonencode({
        principalId                        = "33333333-3333-4333-8333-333333333333"
        roleDefinitionId                   = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        description                        = "Endpoint reader"
        condition                          = var.private_endpoints["explicit"].role_assignments["reader"].condition
        conditionVersion                   = "2.0"
        delegatedManagedIdentityResourceId = var.private_endpoints["explicit"].role_assignments["reader"].delegated_managed_identity_resource_id
        principalType                      = "Group"
      }) &&
      azapi_resource.private_endpoint_role_assignments["explicit-reader"].parent_id == azapi_resource.private_endpoints["explicit"].id &&
      azapi_resource.private_endpoint_locks["explicit"].name == "lock-explicit" &&
      jsonencode(azapi_resource.private_endpoint_locks["explicit"].body) == jsonencode({ properties = { level = "ReadOnly", notes = "Explicit endpoint lock" } }) &&
      azapi_resource.private_endpoint_locks["explicit"].parent_id == azapi_resource.private_endpoints["explicit"].id
    )
    error_message = "Explicit role fields and lock notes must reach ARM without inventing AAD-check or principal-type behavior."
  }

  assert {
    condition = (
      azapi_resource.private_dns_zone_groups["explicit"].name == "zones-explicit" &&
      azapi_resource.private_dns_zone_groups["explicit"].parent_id == azapi_resource.private_endpoints["explicit"].id &&
      azapi_resource.private_dns_zone_groups["explicit"].body.properties.privateDnsZoneConfigs[0].properties.privateDnsZoneId == one(var.private_endpoints["explicit"].private_dns_zone_resource_ids) &&
      azapi_resource.private_endpoints["explicit"].body.properties.applicationSecurityGroups[0].id == var.private_endpoints["explicit"].application_security_group_associations["web"] &&
      azapi_resource.private_endpoints["explicit"].body.properties.subnet.id == var.private_endpoints["explicit"].subnet_resource_id
    )
    error_message = "Existing DNS, security-group and subnet bindings must remain intact."
  }
}

run "explicit_fields_unmanaged_dns" {
  command = apply

  variables {
    private_endpoints_manage_dns_zone_group = false
    private_endpoints = {
      endpoint = {
        name                          = "pe-unmanaged"
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/unit/subnets/endpoints"
        subresource_name              = "custom-group"
        resource_group_name           = "rg-network"
        tags                          = {}
        private_dns_zone_group_name   = "external"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/privateDnsZones/privatelink.openai.azure.com"]
        role_assignments = {
          reader = {
            name                             = "44444444-4444-4444-8444-444444444444"
            principal_id                     = "33333333-3333-4333-8333-333333333333"
            role_definition_id_or_name       = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            skip_service_principal_aad_check = true
          }
        }
        lock = {
          kind  = "CanNotDelete"
          name  = "lock-unmanaged"
          notes = ""
        }
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.6"
            member_name        = "member-unmanaged"
          }
        }
      }
    }
  }

  assert {
    condition = (
      length(azapi_resource.private_endpoints) == 0 &&
      length(azapi_resource.private_dns_zone_groups) == 0 &&
      output.private_endpoints["endpoint"].id == azapi_resource.private_endpoints_unmanaged["endpoint"].id &&
      azapi_resource.private_endpoints_unmanaged["endpoint"].type == "Microsoft.Network/privateEndpoints@2024-05-01" &&
      azapi_resource.private_endpoints_unmanaged["endpoint"].parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network" &&
      data.azapi_resource.existing_private_endpoints["endpoint"].parent_id == azapi_resource.private_endpoints_unmanaged["endpoint"].parent_id &&
      azapi_resource.private_endpoints_unmanaged["endpoint"].body.properties.customNetworkInterfaceName == "nic-custom-group--pe-unmanaged" &&
      azapi_resource.private_endpoints_unmanaged["endpoint"].body.properties.privateLinkServiceConnections[0].name == "pcon-custom-group-pe-unmanaged" &&
      azapi_resource.private_endpoints_unmanaged["endpoint"].body.properties.privateLinkServiceConnections[0].properties.groupIds[0] == "custom-group" &&
      azapi_resource.private_endpoints_unmanaged["endpoint"].body.properties.ipConfigurations[0].properties.groupId == "custom-group" &&
      azapi_resource.private_endpoints_unmanaged["endpoint"].body.properties.ipConfigurations[0].properties.memberName == "member-unmanaged" &&
      length(azapi_resource.private_endpoints_unmanaged["endpoint"].tags) == 0
    )
    error_message = "Unmanaged DNS must preserve its address, legacy group-name input, empty tags and subresource-aware names."
  }

  assert {
    condition = (
      azapi_resource.private_endpoint_role_assignments["endpoint-reader"].name == "44444444-4444-4444-8444-444444444444" &&
      azapi_resource.private_endpoint_role_assignments["endpoint-reader"].parent_id == azapi_resource.private_endpoints_unmanaged["endpoint"].id &&
      azapi_resource.private_endpoint_role_assignments["endpoint-reader"].body.properties.principalType == null &&
      length(keys(azapi_resource.private_endpoint_role_assignments["endpoint-reader"].body.properties)) == 7 &&
      azapi_resource.private_endpoint_locks["endpoint"].parent_id == azapi_resource.private_endpoints_unmanaged["endpoint"].id &&
      jsonencode(azapi_resource.private_endpoint_locks["endpoint"].body) == jsonencode({ properties = { level = "CanNotDelete", notes = "" } })
    )
    error_message = "Unmanaged extensions must use the endpoint parent, honor empty notes and leave principal type uninferred."
  }
}

run "explicit_subresource_generated_names" {
  command = apply

  variables {
    private_endpoints = {
      generated = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/unit/subnets/endpoints"
        subresource_name   = "custom-group"
        tags               = { endpoint = "generated" }
      }
      other = {
        name               = "pe-other"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/unit/subnets/endpoints"
        tags               = { endpoint = "other" }
      }
    }
  }

  assert {
    condition = (
      azapi_resource.private_endpoints["generated"].name == "pep-custom-group-${uuidv5("url", output.resource_id)}" &&
      azapi_resource.private_endpoints["generated"].body.properties.customNetworkInterfaceName == "nic-pep-custom-group-${uuidv5("url", output.resource_id)}" &&
      azapi_resource.private_endpoints["generated"].body.properties.privateLinkServiceConnections[0].name == "pcon-pep-custom-group-${uuidv5("url", output.resource_id)}" &&
      azapi_resource.private_endpoints["generated"].tags == tomap({ endpoint = "generated" }) &&
      azapi_resource.private_endpoints["other"].tags == tomap({ endpoint = "other" })
    )
    error_message = "Explicit subresources must affect generated names without mixing tags between endpoints."
  }
}

run "existing_nic_omitted" {
  command = apply

  variables {
    private_endpoints = {
      endpoint = {
        name               = "pe-existing"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/unit/subnets/endpoints"
      }
    }
  }

  override_data {
    target = data.azapi_resource.existing_private_endpoints["endpoint"]
    values = {
      exists = true
      output = { properties = { customNetworkInterfaceName = "nic-before-migration" } }
    }
  }

  assert {
    condition = (
      azapi_resource.private_endpoints["endpoint"].body.properties.customNetworkInterfaceName == "nic-before-migration" &&
      azapi_resource.private_endpoints["endpoint"].body.properties.privateLinkServiceConnections[0].name == "pcon-account-pe-existing" &&
      length(azapi_resource.private_endpoint_locks) == 0 &&
      length(azapi_resource.private_endpoint_role_assignments) == 0
    )
    error_message = "An existing custom NIC must survive when the NIC input is omitted."
  }
}

run "existing_nic_null" {
  command = apply

  variables {
    private_endpoints = {
      endpoint = {
        name                   = "pe-existing"
        subnet_resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/unit/subnets/endpoints"
        network_interface_name = null
        role_assignments       = null
        lock                   = null
        ip_configurations      = null
      }
    }
  }

  override_data {
    target = data.azapi_resource.existing_private_endpoints["endpoint"]
    values = {
      exists = true
      output = { properties = { customNetworkInterfaceName = "nic-before-migration" } }
    }
  }

  assert {
    condition     = jsonencode(output.private_endpoints["endpoint"].body) == jsonencode(run.existing_nic_omitted.private_endpoints["endpoint"].body)
    error_message = "A null NIC and null optional collections must preserve the omitted-field behavior."
  }
}

run "existing_endpoint_without_custom_nic" {
  command = apply

  variables {
    private_endpoints = {
      endpoint = {
        name               = "pe-existing"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/unit/subnets/endpoints"
      }
    }
  }

  override_data {
    target = data.azapi_resource.existing_private_endpoints["endpoint"]
    values = {
      exists = true
      output = { properties = {} }
    }
  }

  assert {
    condition     = azapi_resource.private_endpoints["endpoint"].body.properties.customNetworkInterfaceName == "nic-account--pe-existing"
    error_message = "An endpoint with no discovered custom NIC must retain the utility's original generated name."
  }
}

run "absent_endpoint_does_not_supply_nic" {
  command = apply

  variables {
    private_endpoints = {
      endpoint = {
        name               = "pe-existing"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/unit/subnets/endpoints"
      }
    }
  }

  override_data {
    target = data.azapi_resource.existing_private_endpoints["endpoint"]
    values = {
      exists = false
      output = { properties = { customNetworkInterfaceName = "not-an-existing-nic" } }
    }
  }

  assert {
    condition     = azapi_resource.private_endpoints["endpoint"].body.properties.customNetworkInterfaceName == "nic-account--pe-existing"
    error_message = "Only a confirmed existing endpoint may supply a discovered NIC name."
  }
}

run "legacy_empty_strings" {
  command = apply

  variables {
    private_endpoints = {
      endpoint = {
        name                            = "pe-empty"
        subnet_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/unit/subnets/endpoints"
        location                        = ""
        resource_group_name             = ""
        network_interface_name          = ""
        private_service_connection_name = ""
        tags                            = {}
      }
    }
  }

  assert {
    condition = (
      azapi_resource.private_endpoints["endpoint"].location == "" &&
      azapi_resource.private_endpoints["endpoint"].parent_id == var.parent_id &&
      azapi_resource.private_endpoints["endpoint"].body.properties.customNetworkInterfaceName == "" &&
      azapi_resource.private_endpoints["endpoint"].body.properties.privateLinkServiceConnections[0].name == "" &&
      length(azapi_resource.private_endpoints["endpoint"].tags) == 0
    )
    error_message = "Previously declared empty-string inputs and empty tags must keep their existing behavior."
  }
}

run "invalid_subnet" {
  command = plan

  variables {
    private_endpoints = {
      endpoint = { subnet_resource_id = "not-a-subnet-id" }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "invalid_dns_zone" {
  command = plan

  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/unit/subnets/endpoints"
        private_dns_zone_resource_ids = ["not-a-dns-zone-id"]
      }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "invalid_security_group" {
  command = plan

  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/unit/subnets/endpoints"
        application_security_group_associations = { invalid = "not-an-application-security-group-id" }
      }
    }
  }

  expect_failures = [var.private_endpoints]
}

run "invalid_delegated_identity" {
  command = plan

  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/unit/subnets/endpoints"
        role_assignments = {
          reader = {
            principal_id                           = "33333333-3333-4333-8333-333333333333"
            role_definition_id_or_name             = "Reader"
            delegated_managed_identity_resource_id = "not-a-managed-identity-id"
          }
        }
      }
    }
  }

  expect_failures = [var.private_endpoints]
}
