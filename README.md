<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-template

This is a template repo for Terraform Azure Verified Modules.

Things to do:

1. Set up a GitHub repo environment called `test`.
1. Configure environment protection rule to ensure that approval is required before deploying to this environment.
1. Create a user-assigned managed identity in your test subscription.
1. Create a role assignment for the managed identity on your test subscription, use the minimum required role.
1. Configure federated identity credentials on the user assigned managed identity. Use the GitHub environment.
1. Create the following environment secrets on the `test` environment:
   1. AZURE\_CLIENT\_ID
   1. AZURE\_TENANT\_ID
   1. AZURE\_SUBSCRIPTION\_ID
1. Search and update TODOs within the code and remove the TODO comments once complete.

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
>
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
>
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.71.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.71.0)

- <a name="provider_random"></a> [random](#provider\_random) (>= 3.5.0)

## Resources

The following resources are used by this module:

- [azurerm_cognitive_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_account) (resource)
- [azurerm_cognitive_account_customer_managed_key.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_account_customer_managed_key) (resource)
- [azurerm_cognitive_deployment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_deployment) (resource)
- [azurerm_private_dns_zone.dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) (resource)
- [azurerm_private_dns_zone_virtual_network_link.private_dns_zone_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) (resource)
- [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [random_string.default_custom_subdomain_name_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) (resource)
- [azurerm_private_dns_zone.dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/private_dns_zone) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_cognitive_account_kind"></a> [cognitive\_account\_kind](#input\_cognitive\_account\_kind)

Description: (Required) Specifies the type of Cognitive Service Account that should be created. Possible values are `Academic`, `AnomalyDetector`, `Bing.Autosuggest`, `Bing.Autosuggest.v7`, `Bing.CustomSearch`, `Bing.Search`, `Bing.Search.v7`, `Bing.Speech`, `Bing.SpellCheck`, `Bing.SpellCheck.v7`, `CognitiveServices`, `ComputerVision`, `ContentModerator`, `ContentSafety`, `CustomSpeech`, `CustomVision.Prediction`, `CustomVision.Training`, `Emotion`, `Face`, `FormRecognizer`, `ImmersiveReader`, `LUIS`, `LUIS.Authoring`, `MetricsAdvisor`, `OpenAI`, `Personalizer`, `QnAMaker`, `Recommendations`, `SpeakerRecognition`, `Speech`, `SpeechServices`, `SpeechTranslation`, `TextAnalytics`, `TextTranslation` and `WebLM`. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_cognitive_account_location"></a> [cognitive\_account\_location](#input\_cognitive\_account\_location)

Description: (Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_cognitive_account_name"></a> [cognitive\_account\_name](#input\_cognitive\_account\_name)

Description: (Required) Specifies the name of the Cognitive Service Account. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_cognitive_account_resource_group_name"></a> [cognitive\_account\_resource\_group\_name](#input\_cognitive\_account\_resource\_group\_name)

Description: (Required) The name of the resource group in which the Cognitive Service Account is created. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_cognitive_account_sku_name"></a> [cognitive\_account\_sku\_name](#input\_cognitive\_account\_sku\_name)

Description: (Required) Specifies the SKU Name for this Cognitive Service Account. Possible values are `F0`, `F1`, `S0`, `S`, `S1`, `S2`, `S3`, `S4`, `S5`, `S6`, `P0`, `P1`, `P2`, `E0` and `DC0`.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_brown_field_private_dns_zone"></a> [brown\_field\_private\_dns\_zone](#input\_brown\_field\_private\_dns\_zone)

Description: An object that represents the existing Private DNS Zone you'd like to use. Leave this variable as default while using private endpoint would create a new Private DNS Zone.  
type = object({  
  name                = "(Required) The name of the Private DNS Zone."  
  resource\_group\_name = "(Optional) The Name of the Resource Group where the Private DNS Zone exists. If the Name of the Resource Group is not provided, the first Private DNS Zone from the list of Private DNS Zones in your subscription that matches `name` will be returned."
}

Type:

```hcl
object({
    name                = string
    resource_group_name = optional(string)
  })
```

Default: `null`

### <a name="input_cognitive_account_custom_question_answering_search_service_id"></a> [cognitive\_account\_custom\_question\_answering\_search\_service\_id](#input\_cognitive\_account\_custom\_question\_answering\_search\_service\_id)

Description: (Optional) If `kind` is `TextAnalytics` this specifies the ID of the Search service.

Type: `string`

Default: `null`

### <a name="input_cognitive_account_custom_question_answering_search_service_key"></a> [cognitive\_account\_custom\_question\_answering\_search\_service\_key](#input\_cognitive\_account\_custom\_question\_answering\_search\_service\_key)

Description: (Optional) If `kind` is `TextAnalytics` this specifies the key of the Search service.

Type: `string`

Default: `null`

### <a name="input_cognitive_account_custom_subdomain_name"></a> [cognitive\_account\_custom\_subdomain\_name](#input\_cognitive\_account\_custom\_subdomain\_name)

Description: (Optional) The subdomain name used for token-based authentication. This property is required when `network_acls` is specified. Changing this forces a new resource to be created.

Type: `string`

Default: `null`

### <a name="input_cognitive_account_customer_managed_key"></a> [cognitive\_account\_customer\_managed\_key](#input\_cognitive\_account\_customer\_managed\_key)

Description: - `identity_client_id` - (Optional) The Client ID of the User Assigned Identity that has access to the key. This property only needs to be specified when there're multiple identities attached to the Cognitive Account.
- `key_vault_key_id` - (Required) The ID of the Key Vault Key which should be used to Encrypt the data in this Cognitive Account.

---
`timeouts` block supports the following:
- `create` - (Defaults to 30 minutes) Used when creating the Cognitive Account Customer Managed Key.
- `delete` - (Defaults to 30 minutes) Used when deleting the Cognitive Account Customer Managed Key.
- `read` - (Defaults to 5 minutes) Used when retrieving the Cognitive Account Customer Managed Key.
- `update` - (Defaults to 30 minutes) Used when updating the Cognitive Account Customer Managed Key.

Type:

```hcl
object({
    identity_client_id = optional(string)
    key_vault_key_id   = string
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
```

Default: `null`

### <a name="input_cognitive_account_dynamic_throttling_enabled"></a> [cognitive\_account\_dynamic\_throttling\_enabled](#input\_cognitive\_account\_dynamic\_throttling\_enabled)

Description: (Optional) Whether to enable the dynamic throttling for this Cognitive Service Account.

Type: `bool`

Default: `null`

### <a name="input_cognitive_account_fqdns"></a> [cognitive\_account\_fqdns](#input\_cognitive\_account\_fqdns)

Description: (Optional) List of FQDNs allowed for the Cognitive Account.

Type: `list(string)`

Default: `null`

### <a name="input_cognitive_account_identity"></a> [cognitive\_account\_identity](#input\_cognitive\_account\_identity)

Description: - `identity_ids` - (Optional) Specifies a list of User Assigned Managed Identity IDs to be assigned to this Cognitive Account.
- `type` - (Required) Specifies the type of Managed Service Identity that should be configured on this Cognitive Account. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both).

Type:

```hcl
object({
    identity_ids = optional(set(string))
    type         = string
  })
```

Default: `null`

### <a name="input_cognitive_account_local_auth_enabled"></a> [cognitive\_account\_local\_auth\_enabled](#input\_cognitive\_account\_local\_auth\_enabled)

Description: (Optional) Whether local authentication methods is enabled for the Cognitive Account. Defaults to `true`.

Type: `bool`

Default: `null`

### <a name="input_cognitive_account_metrics_advisor_aad_client_id"></a> [cognitive\_account\_metrics\_advisor\_aad\_client\_id](#input\_cognitive\_account\_metrics\_advisor\_aad\_client\_id)

Description: (Optional) The Azure AD Client ID (Application ID). This attribute is only set when kind is `MetricsAdvisor`. Changing this forces a new resource to be created.

Type: `string`

Default: `null`

### <a name="input_cognitive_account_metrics_advisor_aad_tenant_id"></a> [cognitive\_account\_metrics\_advisor\_aad\_tenant\_id](#input\_cognitive\_account\_metrics\_advisor\_aad\_tenant\_id)

Description: (Optional) The Azure AD Tenant ID. This attribute is only set when kind is `MetricsAdvisor`. Changing this forces a new resource to be created.

Type: `string`

Default: `null`

### <a name="input_cognitive_account_metrics_advisor_super_user_name"></a> [cognitive\_account\_metrics\_advisor\_super\_user\_name](#input\_cognitive\_account\_metrics\_advisor\_super\_user\_name)

Description: (Optional) The super user of Metrics Advisor. This attribute is only set when kind is `MetricsAdvisor`. Changing this forces a new resource to be created.

Type: `string`

Default: `null`

### <a name="input_cognitive_account_metrics_advisor_website_name"></a> [cognitive\_account\_metrics\_advisor\_website\_name](#input\_cognitive\_account\_metrics\_advisor\_website\_name)

Description: (Optional) The website name of Metrics Advisor. This attribute is only set when kind is `MetricsAdvisor`. Changing this forces a new resource to be created.

Type: `string`

Default: `null`

### <a name="input_cognitive_account_network_acls"></a> [cognitive\_account\_network\_acls](#input\_cognitive\_account\_network\_acls)

Description: - `default_action` - (Required) The Default Action to use when no rules match from `ip_rules` / `virtual_network_rules`. Possible values are `Allow` and `Deny`.
- `ip_rules` - (Optional) One or more IP Addresses, or CIDR Blocks which should be able to access the Cognitive Account.

---
`virtual_network_rules` block supports the following:
- `ignore_missing_vnet_service_endpoint` - (Optional) Whether ignore missing vnet service endpoint or not. Default to `false`.
- `subnet_id` - (Required) The ID of the subnet which should be able to access this Cognitive Account.

Type:

```hcl
object({
    default_action = string
    ip_rules       = optional(set(string))
    virtual_network_rules = optional(set(object({
      ignore_missing_vnet_service_endpoint = optional(bool)
      subnet_id                            = string
    })))
  })
```

Default: `null`

### <a name="input_cognitive_account_outbound_network_access_restricted"></a> [cognitive\_account\_outbound\_network\_access\_restricted](#input\_cognitive\_account\_outbound\_network\_access\_restricted)

Description: (Optional) Whether outbound network access is restricted for the Cognitive Account. Defaults to `false`.

Type: `bool`

Default: `null`

### <a name="input_cognitive_account_public_network_access_enabled"></a> [cognitive\_account\_public\_network\_access\_enabled](#input\_cognitive\_account\_public\_network\_access\_enabled)

Description: (Optional) Whether public network access is allowed for the Cognitive Account. Defaults to `true`.

Type: `bool`

Default: `null`

### <a name="input_cognitive_account_qna_runtime_endpoint"></a> [cognitive\_account\_qna\_runtime\_endpoint](#input\_cognitive\_account\_qna\_runtime\_endpoint)

Description: (Optional) A URL to link a QnAMaker cognitive account to a QnA runtime.

Type: `string`

Default: `null`

### <a name="input_cognitive_account_storage"></a> [cognitive\_account\_storage](#input\_cognitive\_account\_storage)

Description: - `identity_client_id` - (Optional) The client ID of the managed identity associated with the storage resource.
- `storage_account_id` - (Required) Full resource id of a Microsoft.Storage resource.

Type:

```hcl
list(object({
    identity_client_id = optional(string)
    storage_account_id = string
  }))
```

Default: `null`

### <a name="input_cognitive_account_tags"></a> [cognitive\_account\_tags](#input\_cognitive\_account\_tags)

Description: (Optional) A mapping of tags to assign to the resource.

Type: `map(string)`

Default: `null`

### <a name="input_cognitive_account_timeouts"></a> [cognitive\_account\_timeouts](#input\_cognitive\_account\_timeouts)

Description: - `create` - (Defaults to 30 minutes) Used when creating the Cognitive Service Account.
- `delete` - (Defaults to 30 minutes) Used when deleting the Cognitive Service Account.
- `read` - (Defaults to 5 minutes) Used when retrieving the Cognitive Service Account.
- `update` - (Defaults to 30 minutes) Used when updating the Cognitive Service Account.

Type:

```hcl
object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
```

Default: `null`

### <a name="input_cognitive_deployments"></a> [cognitive\_deployments](#input\_cognitive\_deployments)

Description: - `name` - (Required) The name of the Cognitive Services Account Deployment. Changing this forces a new resource to be created.
- `rai_policy_name` - (Optional) The name of RAI policy.
- `version_upgrade_option` - (Optional) Deployment model version upgrade option. Possible values are `OnceNewDefaultVersionAvailable`, `OnceCurrentVersionExpired`, and `NoAutoUpgrade`. Defaults to `OnceNewDefaultVersionAvailable`. Changing this forces a new resource to be created.

---
`model` block supports the following:
- `format` - (Required) The format of the Cognitive Services Account Deployment model. Changing this forces a new resource to be created. Possible value is `OpenAI`.
- `name` - (Required) The name of the Cognitive Services Account Deployment model. Changing this forces a new resource to be created.
- `version` - (Optional) The version of Cognitive Services Account Deployment model. If `version` is not specified, the default version of the model at the time will be assigned.

---
`scale` block supports the following:
- `capacity` - (Optional) Tokens-per-Minute (TPM). The unit of measure for this field is in the thousands of Tokens-per-Minute. Defaults to `1` which means that the limitation is `1000` tokens per minute. If the resources SKU supports scale in/out then the capacity field should be included in the resources' configuration. If the scale in/out is not supported by the resources SKU then this field can be safely omitted. For more information about TPM please see the [product documentation](https://learn.microsoft.com/azure/ai-services/openai/how-to/quota?tabs=rest).
- `family` - (Optional) If the service has different generations of hardware, for the same SKU, then that can be captured here. Changing this forces a new resource to be created.
- `size` - (Optional) The SKU size. When the name field is the combination of tier and some other value, this would be the standalone code. Changing this forces a new resource to be created.
- `tier` - (Optional) Possible values are `Free`, `Basic`, `Standard`, `Premium`, `Enterprise`. Changing this forces a new resource to be created.
- `type` - (Required) The name of the SKU. Ex

---
`timeouts` block supports the following:
- `create` - (Defaults to 30 minutes) Used when creating the Cognitive Services Account Deployment.
- `delete` - (Defaults to 30 minutes) Used when deleting the Cognitive Services Account Deployment.
- `read` - (Defaults to 5 minutes) Used when retrieving the Cognitive Services Account Deployment.
- `update` - (Defaults to 30 minutes) Used when updating the Cognitive Services Account Deployment.

Type:

```hcl
map(object({
    name                   = string
    rai_policy_name        = optional(string)
    version_upgrade_option = optional(string)
    model = object({
      format  = string
      name    = string
      version = string
    })
    scale = object({
      capacity = optional(number)
      family   = optional(string)
      size     = optional(string)
      tier     = optional(string)
      type     = string
    })
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  }))
```

Default: `{}`

### <a name="input_green_field_private_dns_zone"></a> [green\_field\_private\_dns\_zone](#input\_green\_field\_private\_dns\_zone)

Description: An object that represents the Private DNS Zone you'd like to create in this module.
- `resource_group_name` - (Required) Specifies the resource group where the resource exists. Changing this forces a new resource to be created.
- `tags` - (Optional) A mapping of tags to assign to the resource.
---
`timeouts` block supports the following:
- `create` - (Defaults to 30 minutes) Used when creating the Private DNS Zone.
- `delete` - (Defaults to 30 minutes) Used when deleting the Private DNS Zone.
- `read` - (Defaults to 5 minutes) Used when retrieving the Private DNS Zone.
- `update` - (Defaults to 30 minutes) Used when updating the Private DNS Zone.

Type:

```hcl
object({
    resource_group_name = string
    tags                = optional(map(string))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
```

Default: `null`

### <a name="input_pe_subresource_names"></a> [pe\_subresource\_names](#input\_pe\_subresource\_names)

Description: A list of subresource names which the Private Endpoint is able to connect to. `subresource_names` corresponds to `group_id`. Possible values are detailed in the product [documentation](https://docs.microsoft.com/azure/private-link/private-endpoint-overview#private-link-resource) in the `Subresources` column. Changing this forces a new resource to be created.

Type: `list(string)`

Default:

```json
[
  "account"
]
```

### <a name="input_private_endpoint"></a> [private\_endpoint](#input\_private\_endpoint)

Description: A map of objects that represent the configuration for a private endpoint."  
type = map(object({  
  name                               = (Required) Specifies the Name of the Private Endpoint. Changing this forces a new resource to be created.  
  vnet\_key                           = (Required) Map key of the virtual network in `var.private_endpoint_subnets` where the Private Endpoint's exists. Changing this forces a new resource to be created.  
  subnet\_key                         = (Required) Map key of the `subnets` in `var.private_endpoint_subnets` where the subnet that this Private IP Addresses will be created in. Changing this forces a new resource to be created.  
  resource\_group\_name                = (Optional) Specifies the Name of the Resource Group within which the Private Endpoint should exist. Omit this field would use cognitive account's resource group name. Changing this forces a new resource to be created.  
  dns\_zone\_virtual\_network\_link\_name = (Optional) The name of the Private DNS Zone Virtual Network Link. Changing this forces a new resource to be created. Default to `dns_zone_link`.  
  private\_dns\_entry\_enabled          = (Optional) Whether or not to create a `private_dns_zone_group` block for the Private Endpoint. Default to `false`.  
  private\_service\_connection\_name    = (Optional) Specifies the Name of the Private Service Connection. Changing this forces a new resource to be created. Default to `privateserviceconnection`.  
  is\_manual\_connection               = (Optional) Does the Private Endpoint require Manual Approval from the remote resource owner? Changing this forces a new resource to be created. Default to `false`.  
  tags                               = (Optional) A mapping of tags to assign to the resource.
}))

Type:

```hcl
map(object({
    name                            = string
    vnet_key                        = string
    subnet_key                      = string
    resource_group_name             = optional(string)
    private_dns_entry_enabled       = optional(bool, false)
    private_service_connection_name = optional(string, "privateserviceconnection")
    is_manual_connection            = optional(bool, false)
    tags                            = optional(map(string), {})
  }))
```

Default: `{}`

### <a name="input_private_endpoint_subnets"></a> [private\_endpoint\_subnets](#input\_private\_endpoint\_subnets)

Description: Please be advised! We won't try to create `azurerm_private_dns_zone_virtual_network_link` if `var.green_field_private_dns_zone`. If you're using brown field private dns zone, you need link the private dns zone with the virtual network yourself.  
A map of objects that represent the virtual networks and subnets for private endpoints.  
Map's key must be a static literal value.  
type = map(object({  
  vnet\_id = The Virtual Network's ID which private endpoint is created in. Changing this forces a new resource to be created.  
  vnet\_dns\_zone\_link\_name = The name of the Private DNS Zone Virtual Network Link. Defaults to "<Private Dns Zone Name>-<VNet Key>". Changing this forces a new resource to be created.  
  vnet\_dns\_zone\_link\_tags = (Optional) A mapping of tags to assign to the `azurerm_private_dns_zone_virtual_network_link` resource. Changing this forces a new resource to be created.  
  subnets = map(object({  
    id = The Subnet's ID which private endpoint is created in. Changing this forces a new resource to be created.
  }))
}))

Type:

```hcl
map(object({
    vnet_id                 = string
    vnet_dns_zone_link_name = optional(string)
    vnet_dns_zone_link_tags = optional(map(string), {})
    subnets = map(object({
      id = string
    }))
  }))
```

Default: `{}`

## Outputs

No outputs.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->