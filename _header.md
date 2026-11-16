# terraform-azurerm-avm-res-cognitiveservices-account

This Terraform module is designed to manage Azure Cognitive Services. It provides a comprehensive set of variables and resources to configure and deploy Cognitive Services in Azure.

## Project APIM connections (preview)

For a runnable Terraform configuration using the connection child, see
[`examples/project-connection`](examples/project-connection). It deploys a
connection in an existing project against an existing gateway and includes
instructions for supplying inputs, planning, applying and cleanup.

`modules/project-connection` independently manages one
`Microsoft.CognitiveServices/accounts/projects/connections` resource beneath an
existing project. It exposes a static OpenAI model catalog through an existing
APIM gateway using `ProjectManagedIdentity`. It does not create projects, gateways,
routes, policies, identities or authorization, and catalog visibility does not
prove inference readiness.

The optional `project_connections` map composes these children for projects that
already exist in this AIServices account. When another module creates the project
using this account's ID, source the connection submodule directly with that project's
ID instead, avoiding a dependency cycle. See the [submodule documentation](modules/project-connection/README.md)
for the exact preview contract and runtime prerequisites. Existing account,
deployment and RAI-policy addresses and defaults are unchanged.

`resource_types.cognitiveservices_accounts` retains the account API default
`2025-06-01`; the matching `ignore_body_changes` list defaults to empty and adds
no ignores. Both account variants share these controls; the existing HSM
encryption updater shares the API control only because its provider resource does
not support `ignore_body_changes`. Matching controls for existing private endpoints,
DNS zone groups, private endpoint role assignments and locks retain the exact API
defaults from the pinned interfaces module and add no ignores by default. Existing
static lifecycle ignores are preserved. These controls do not retrofit the
deployment or RAI-policy interfaces or create any additional resources.

### Example: use the connection child through the account module

The following consumer configuration uses a local checkout of this repository.
Keep the account module's existing name, inputs and state address when adding
`project_connections`; do not create a second owner for an existing account.
The `research` project must already exist in that account, with an identity
authorized to call the existing gateway.

```hcl
module "cognitive_services" {
  source = "./terraform-azurerm-avm-res-cognitiveservices-account"

  kind               = "AIServices"
  location           = var.location
  name               = var.account_name
  parent_id          = var.resource_group_resource_id
  sku_name           = "S0"
  local_auth_enabled = false

  project_connections = {
    gateway = {
      project_name = "research"
      name         = "enterprise-models"
      audience     = "api://gateway"
      target       = "https://gateway.example.com/ai/v1"
      models = {
        chat = {
          model_name    = "gpt-4.1"
          model_version = "2025-04-14"
        }
      }
    }
  }
}

output "gateway_model_reference" {
  value = module.cognitive_services.project_connection_model_references["gateway"]["chat"]
}
```

The consumer supplies `location`, `account_name` and `resource_group_resource_id`
for its managed account. The output is `enterprise-models/chat`, which an agent
must explicitly select. The parent creates one connection child per map entry
and also exposes `project_connection_resource_ids` keyed by those entries.
The example gateway URL and audience are placeholders: replace them with the
gateway owner's values and verify routes, authorization and inference separately.

This is not a fresh account-and-project deployment example: the account module
does not create projects. If the project is created in the same Terraform graph
using this account's output, call `modules/project-connection` directly with the
project's ARM ID instead of feeding that project back into the account module.
For Registry consumption, pin an actual release that contains the child;
`v0.12.0` does not contain it.

## Private endpoint interface compatibility

Private endpoints now honor `role_assignments[*].name`, `lock.notes`, `subresource_name`, and `ip_configurations[*].member_name`. Existing generated endpoint, NIC, connection and role assignment names are unchanged when these fields are omitted or null. Omitted or null lock notes are not sent to Azure; explicit notes, including an empty string, are preserved. The subresource still defaults to `account` and the IP configuration member to `default`. Per-endpoint tags remain independent of the account's tags.

Review the plan if these fields were previously supplied but ignored: an explicit role assignment name replaces that assignment when it differs from its generated UUID. A non-default subresource changes connection/IP group IDs and generated endpoint, NIC and connection names; changing the endpoint name replaces the endpoint and its child resources. Lock notes and IP member names are now sent to ARM. `skip_service_principal_aad_check` remains an AzureRM compatibility flag with no AzAPI effect; it neither sends an ARM property nor infers `principal_type`.

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
