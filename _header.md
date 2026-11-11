# terraform-azurerm-avm-res-cognitiveservices-account

This Terraform module is designed to manage Azure Cognitive Services. It provides a comprehensive set of variables and resources to configure and deploy Cognitive Services in Azure.

## Private endpoint interface compatibility

Private endpoints now honor `role_assignments[*].name`, `lock.notes`, `subresource_name`, and `ip_configurations[*].member_name`. Existing generated endpoint, NIC, connection and role assignment names are unchanged when these fields are omitted or null. Omitted or null lock notes are not sent to Azure; explicit notes, including an empty string, are preserved. The subresource still defaults to `account` and the IP configuration member to `default`. Per-endpoint tags remain independent of the account's tags.

Review the plan if these fields were previously supplied but ignored: an explicit role assignment name replaces that assignment when it differs from its generated UUID. A non-default subresource changes connection/IP group IDs and generated endpoint, NIC and connection names; changing the endpoint name replaces the endpoint and its child resources. Lock notes and IP member names are now sent to ARM. `skip_service_principal_aad_check` remains an AzureRM compatibility flag with no AzAPI effect; it neither sends an ARM property nor infers `principal_type`.

## Child resource tags

Deployments and RAI policies accept per-item `tags` through `cognitive_deployments` and `rai_policies`, or `tags` when using their submodules directly. Omitted or null tags retain provider defaults and do not inherit account tags. Previously ignored supplied tags now update the child's tags; an empty map explicitly selects no tags. These bindings do not change resource names, addresses or API versions and add no replacement triggers.

## Telemetry migration compatibility

The root and its deployment and RAI policy submodules no longer require the ModTM provider. When enabled, telemetry now uses an empty subscription-scoped Azure deployment and requires `Microsoft.Resources/deployments/read`, `Microsoft.Resources/deployments/write`, and `Microsoft.Resources/deployments/delete` permissions at the active subscription. Set `enable_telemetry = false` to disable these deployments; the parent forwards this setting and its `location` to both submodules.

Direct deployment or RAI policy submodule callers must supply `location` when telemetry is enabled. Previously deployed telemetry state is forgotten with `destroy = false`; Terraform can still require the old providers for the first initialization of an existing state. Business resource addresses and API versions are unchanged.

The private-endpoint example now uses published AVM Virtual Network `0.23.0` instead of legacy `Azure/vnet` `5.0.1`, which still required ModTM. Its VNet and subnet resource addresses differ: use fresh disposable example infrastructure or review and explicitly migrate existing example state before applying. This does not change networking owned by callers of the Cognitive Services module.

## Upgrading the lock, role assignments and diagnostic settings to AzAPI

The lock, role assignments and diagnostic settings move from AzureRM to AzAPI with `moved` blocks, so the plan after upgrading reports them as moved and Azure keeps them. Two cases need extra steps:

- **`ReadOnly` lock.** The upgrade updates resources in place, which a `ReadOnly` lock blocks. Before upgrading, apply your configuration without the lock using the old version, then upgrade and restore the lock.
- **Cross-tenant role assignments** (those that set `delegated_managed_identity_resource_id`, for example with Azure Lighthouse). The AzureRM provider stored their ID with a `|<tenant-id>` suffix that a `moved` block cannot convert. Before planning, remove each one from the state, then import it at its new address with an `import` block in your root module:

  ```shell
  terraform state rm 'module.<module-name>.azurerm_role_assignment.this["<key>"]'
  ```

  ```hcl
  import {
    to = module.<module-name>.azapi_resource.role_assignments["<key>"]
    id = "<role assignment resource ID, without the |<tenant-id> suffix>"
  }
  ```

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
>
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
>
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

## Migration Guide for Private Endpoint Users

> [!WARNING]
> **Breaking Change for Private Endpoint Users (v0.10.x → v0.11.0+)**
>
> If you are using `private_endpoints` with `private_endpoints_manage_dns_zone_group = true`, upgrading from v0.10.x or earlier requires an import operation to prevent resource recreation.
>
> The module has migrated from `azurerm_private_endpoint` to `azapi_resource` for better control and retry logic. DNS zone groups that were previously embedded now need to be imported as separate resources.
>
> **Required Steps:**
>
> 1. Before upgrading the module version, add an import block for each private endpoint's DNS zone group:
>
> ```hcl
> import {
>   to = module.your_module_name.azapi_resource.private_dns_zone_groups["your_pe_key"]
>   id = "${module.your_module_name.private_endpoints["your_pe_key"].id}/privateDnsZoneGroups/default"
> }
> ```
>
> 2. Run: `terraform plan -generate-config-out=generated.tf`
> 3. Run: `terraform apply`
> 4. Once imported successfully, remove the import block
>
> **Example:**
>
> ```hcl
> # Uncomment when upgrading from v0.10.x to import existing DNS zone groups
> import {
>   to = module.cognitive_service.azapi_resource.private_dns_zone_groups["pe_endpoint"]
>   id = "${module.cognitive_service.private_endpoints["pe_endpoint"].id}/privateDnsZoneGroups/default"
> }
> ```
>
> If you have `private_endpoints_manage_dns_zone_group = false`, no action is required.
