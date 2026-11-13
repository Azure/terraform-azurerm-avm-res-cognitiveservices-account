# terraform-azurerm-avm-res-cognitiveservices-account

This Terraform module is designed to manage Azure Cognitive Services. It provides a comprehensive set of variables and resources to configure and deploy Cognitive Services in Azure.

## Deployment capacity and quota

`cognitive_deployments[*].scale.capacity` is the requested capacity, not an upper bound. The module does not automatically lower capacity when quota is insufficient. Request the required quota before deployment, or explicitly choose a lower initial capacity and increase it after quota approval.

If a calling configuration already obtains available quota, it can calculate `capacity = min(desired_capacity, available_capacity)` before passing it to this module. The caller must account for the model, version, region, SKU and other deployments sharing that quota. A quota lookup is not a reservation: concurrent deployments can consume it before apply. Do not silently substitute zero or a default capacity when a quota lookup fails.

## Private endpoint interface compatibility

Private endpoints now honor `role_assignments[*].name`, `lock.notes`, `subresource_name`, and `ip_configurations[*].member_name`. Existing generated endpoint, NIC, connection and role assignment names are unchanged when these fields are omitted or null. Omitted or null lock notes are not sent to Azure; explicit notes, including an empty string, are preserved. The subresource still defaults to `account` and the IP configuration member to `default`. Per-endpoint tags remain independent of the account's tags.

Review the plan if these fields were previously supplied but ignored: an explicit role assignment name replaces that assignment when it differs from its generated UUID. A non-default subresource changes connection/IP group IDs and generated endpoint, NIC and connection names; changing the endpoint name replaces the endpoint and its child resources. Lock notes and IP member names are now sent to ARM. `skip_service_principal_aad_check` remains an AzureRM compatibility flag with no AzAPI effect; it neither sends an ARM property nor infers `principal_type`.

When a DNS zone group contains multiple zones, each config uses a deterministic name derived from the full zone resource ID to avoid duplicate child names. Empty and single-zone groups retain their existing config names. Existing DNS zone group bodies remain protected by the migration-related `ignore_changes`; this fix does not reconcile DNS membership changes for groups already in state.

## Child resource tags

Deployments and RAI policies accept per-item `tags` through `cognitive_deployments` and `rai_policies`, or `tags` when using their submodules directly. Omitted or null tags retain provider defaults and do not inherit account tags. Previously ignored supplied tags now update the child's tags; an empty map explicitly selects no tags. These bindings do not change resource names, addresses or API versions and add no replacement triggers.

## Telemetry migration compatibility

The root and its deployment and RAI policy submodules no longer require the ModTM provider. When enabled, telemetry now uses an empty subscription-scoped Azure deployment and requires `Microsoft.Resources/deployments/read`, `Microsoft.Resources/deployments/write`, and `Microsoft.Resources/deployments/delete` permissions at the active subscription. Set `enable_telemetry = false` to disable these deployments; the parent forwards this setting and its `location` to both submodules.

Direct deployment or RAI policy submodule callers must supply `location` when telemetry is enabled. Previously deployed telemetry state is forgotten with `destroy = false`; Terraform can still require the old providers for the first initialization of an existing state. Business resource addresses and API versions are unchanged.

The private-endpoint example now uses published AVM Virtual Network `0.23.0` instead of legacy `Azure/vnet` `5.0.1`, which still required ModTM. Its VNet and subnet resource addresses differ: use fresh disposable example infrastructure or review and explicitly migrate existing example state before applying. This does not change networking owned by callers of the Cognitive Services module.

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

## Migration guide for deployments and RAI policies

Version 0.11.1 extracted root-level deployment and RAI policy resources into keyed submodules. Terraform cannot generically move resource instance keys into module instance keys. The former module-level `moved` blocks did not preserve these addresses and have been removed. Removing them alone does **not** prevent recreation: callers with old addresses must declare one move per instance.

Before upgrading, back up your state using your backend's supported backup mechanism and inspect it with `terraform state list`. If it contains root-level AzAPI deployment or policy resources, add per-key moves to your calling configuration:

```hcl
moved {
  from = module.cognitive_service.azapi_resource.cognitive_deployment["gpt-4o"]
  to   = module.cognitive_service.module.deployment["gpt-4o"].azapi_resource.this
}

moved {
  from = module.cognitive_service.azapi_resource.rai_policy["policy0"]
  to   = module.cognitive_service.module.rai_policy["policy0"].azapi_resource.this
}
```

Replace the module path and keys with the exact addresses from your state, including any instance keys on the calling module. Keep these moves in your configuration until every workspace has migrated. If state is already at the keyed submodule addresses, no move is needed.

If you previously followed a plan that moved state to an intermediate address such as `module.cognitive_service.module.deployment.azapi_resource.this["gpt-4o"]`, use that exact address as the source instead. State still using `azurerm_cognitive_deployment.this` requires a provider migration as well; do not use `terraform state mv` between different resource types.

Review the upgrade plan before applying. There must be no deployment or policy creations, deletions or replacements caused by the address change. Stop if Terraform proposes recreation. A real-state upgrade and subsequent no-change plan are required before rolling this migration out to production.

## Migrating from terraform-azurerm-openai

Migration from the archived [Azure/terraform-azurerm-openai](https://github.com/Azure/terraform-azurerm-openai) module is not a drop-in module source change. Resource addresses, provider types, inputs and generated defaults differ.

Inventory the existing state and Azure resource IDs before changing configuration. Preserve the existing account name, location, SKU, custom subdomain, identity, network restrictions and tags, including any tags generated by the old module. For deployments, map the old `deployment` entries to `cognitive_deployments`, preserving each deployment name and its actual model and scale settings:

| Old input | New input |
|---|---|
| `deployment[*].model_format` | `cognitive_deployments[*].model.format` |
| `deployment[*].model_name` | `cognitive_deployments[*].model.name` |
| `deployment[*].model_version` | `cognitive_deployments[*].model.version` |
| `deployment[*].scale_type` | `cognitive_deployments[*].scale.type` |
| `deployment[*].capacity` | `cognitive_deployments[*].scale.capacity` |

Supply the existing resource group's full ARM ID as `parent_id` and set `kind = "OpenAI"`. Explicitly configure the current `name` and `custom_subdomain_name`; the old module's randomly generated defaults are not regenerated with the same values.

The old account address is `module.openai.azurerm_cognitive_account.this`; the new account address is `module.cognitive_service.azapi_resource.this[0]`. Old deployment addresses are `module.openai.azurerm_cognitive_deployment.this["<key>"]`; new ones are `module.cognitive_service.module.deployment["<key>"].azapi_resource.this`. The deployment/RAI policy moves above address an AzAPI-to-AzAPI upgrade only and do not establish this cross-provider migration.

Use a provider-supported declarative move only after verifying support for the exact resource types and provider versions. Otherwise, plan a controlled state handoff: remove the old address from management without destroying Azure resources, then import the same resource ID at the new address. Never apply a plan that destroys the old resource to create the new one. Do not keep both addresses managing the same Azure object.

Migrate private endpoints, DNS zone groups, diagnostic settings, role assignments, locks and customer-managed keys separately if present. In particular, do not destroy an old CMK resource during the handoff, since its deletion can change account encryption. Keep the old provider available until the old state has been migrated. Test the complete handoff on disposable infrastructure first, and require a subsequent no-change plan. This guidance is not a tested automated migration for every historical module version.
