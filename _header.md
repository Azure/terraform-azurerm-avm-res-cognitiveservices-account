# terraform-azurerm-avm-res-cognitiveservices-account

This Terraform module is designed to manage Azure Cognitive Services. It provides a comprehensive set of variables and resources to configure and deploy Cognitive Services in Azure.

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

## Migration Guide for Cognitive Deployments and RAI Policies

> [!WARNING]
> **Breaking Change for `cognitive_deployments` and `rai_policies` Users (v0.11.1 → v0.12.0+)**
>
> v0.11.1 relocated model deployments and RAI policies from root-level resources into the
> `modules/deployment` and `modules/rai_policy` submodules, and shipped `moved` blocks that
> Terraform cannot resolve. A `moved` block cannot carry a resource's instance keys across
> into module instance keys, so the move resolved to
> `module.deployment.azapi_resource.this["<key>"]` — an address that does not exist — and
> Terraform planned a **destroy and recreate of every deployment**. Destroying a live
> `Microsoft.CognitiveServices/accounts/deployments` drops the model endpoint during apply.
>
> Those `moved` blocks have been removed. Because AVM
> [TFRMNFR1](https://azure.github.io/Azure-Verified-Modules/spec/TFRMNFR1) requires
> cardinality to stay on the submodule call, this migration cannot be shipped inside the
> module — declare per-key `moved` blocks in your own configuration instead.
>
> **Who needs to act:** anyone with a non-empty `cognitive_deployments` or `rai_policies`
> whose state still holds `azapi_resource.cognitive_deployment` / `azapi_resource.rai_policy`
> (that is, anyone on v0.11.0 or earlier, and anyone on v0.11.1 who has not applied the
> destructive plan). If you already applied v0.11.1 your state is at the new addresses and
> **no action is required**.
>
> **Always run `terraform plan` and confirm it reports no changes before applying.**
>
> **Step 1 — generate the `moved` blocks from your current state:**
>
> ```bash
> terraform state list \
>   | grep -E '\.azapi_resource\.(cognitive_deployment|rai_policy)\[' \
>   | while IFS= read -r addr; do
>       prefix="${addr%%.azapi_resource.*}"
>       rest="${addr#*.azapi_resource.}"
>       rtype="${rest%%\[*}"
>       key="${rest#*[\"}"; key="${key%\"]}"
>       case "$rtype" in
>         cognitive_deployment) sub="deployment" ;;
>         rai_policy)           sub="rai_policy" ;;
>       esac
>       printf 'moved {\n  from = %s\n  to   = %s.module.%s["%s"].azapi_resource.this\n}\n\n' \
>         "$addr" "$prefix" "$sub" "$key"
>     done
> ```
>
> **Step 2 — paste the output into your root configuration alongside the version bump:**
>
> ```hcl
> moved {
>   from = module.cognitive_service.azapi_resource.cognitive_deployment["gpt-4o"]
>   to   = module.cognitive_service.module.deployment["gpt-4o"].azapi_resource.this
> }
>
> moved {
>   from = module.cognitive_service.azapi_resource.rai_policy["policy0"]
>   to   = module.cognitive_service.module.rai_policy["policy0"].azapi_resource.this
> }
> ```
>
> **Step 3** — run `terraform plan`. It must report **no changes** for the deployment and
> policy resources. If it still plans a destroy, a key is missing or misspelled; do not
> apply. Once applied, the `moved` blocks can be deleted.
>
> **Upgrading from a pre-`azapi` version:** if your state still holds
> `azurerm_cognitive_deployment.this["<key>"]`, move it straight to the new address in one
> hop — the `azapi` provider supports the cross-type move:
>
> ```hcl
> moved {
>   from = module.cognitive_service.azurerm_cognitive_deployment.this["gpt-4o"]
>   to   = module.cognitive_service.module.deployment["gpt-4o"].azapi_resource.this
> }
> ```
