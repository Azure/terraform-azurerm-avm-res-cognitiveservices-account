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
> **Breaking Change for Private Endpoint Users (v0.10.2 → v0.11.0+)**
>
> If you are using `private_endpoints` with `private_endpoints_manage_dns_zone_group = true`, upgrading from v0.10.2 or earlier requires an import operation to prevent resource recreation.
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
> # Uncomment when upgrading from v0.10.2 to import existing DNS zone groups
> import {
>   to = module.cognitive_service.azapi_resource.private_dns_zone_groups["pe_endpoint"]
>   id = "${module.cognitive_service.private_endpoints["pe_endpoint"].id}/privateDnsZoneGroups/default"
> }
> ```
>
> If you have `private_endpoints_manage_dns_zone_group = false`, no action is required.
