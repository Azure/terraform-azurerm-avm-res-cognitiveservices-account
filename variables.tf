variable "cognitive_account_kind" {
  type        = string
  description = "(Required) Specifies the type of Cognitive Service Account that should be created. Possible values are `Academic`, `AnomalyDetector`, `Bing.Autosuggest`, `Bing.Autosuggest.v7`, `Bing.CustomSearch`, `Bing.Search`, `Bing.Search.v7`, `Bing.Speech`, `Bing.SpellCheck`, `Bing.SpellCheck.v7`, `CognitiveServices`, `ComputerVision`, `ContentModerator`, `ContentSafety`, `CustomSpeech`, `CustomVision.Prediction`, `CustomVision.Training`, `Emotion`, `Face`, `FormRecognizer`, `ImmersiveReader`, `LUIS`, `LUIS.Authoring`, `MetricsAdvisor`, `OpenAI`, `Personalizer`, `QnAMaker`, `Recommendations`, `SpeakerRecognition`, `Speech`, `SpeechServices`, `SpeechTranslation`, `TextAnalytics`, `TextTranslation` and `WebLM`. Changing this forces a new resource to be created."
  nullable    = false
}

variable "cognitive_account_location" {
  type        = string
  description = "(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  nullable    = false
}

variable "cognitive_account_name" {
  type        = string
  description = "(Required) Specifies the name of the Cognitive Service Account. Changing this forces a new resource to be created."
  nullable    = false
}

variable "cognitive_account_resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which the Cognitive Service Account is created. Changing this forces a new resource to be created."
  nullable    = false
}

variable "cognitive_account_sku_name" {
  type        = string
  description = "(Required) Specifies the SKU Name for this Cognitive Service Account. Possible values are `F0`, `F1`, `S0`, `S`, `S1`, `S2`, `S3`, `S4`, `S5`, `S6`, `P0`, `P1`, `P2`, `E0` and `DC0`."
  nullable    = false
}

variable "brown_field_private_dns_zone" {
  type = object({
    name                = string
    resource_group_name = optional(string)
  })
  default     = null
  description = <<-DESCRIPTION
  An object that represents the existing Private DNS Zone you'd like to use. Leave this variable as default while using private endpoint would create a new Private DNS Zone.
  type = object({
    name                = "(Required) The name of the Private DNS Zone."
    resource_group_name = "(Optional) The Name of the Resource Group where the Private DNS Zone exists. If the Name of the Resource Group is not provided, the first Private DNS Zone from the list of Private DNS Zones in your subscription that matches `name` will be returned."
  }
DESCRIPTION
}

variable "cognitive_account_custom_question_answering_search_service_id" {
  type        = string
  default     = null
  description = "(Optional) If `kind` is `TextAnalytics` this specifies the ID of the Search service."
}

variable "cognitive_account_custom_question_answering_search_service_key" {
  type        = string
  default     = null
  description = "(Optional) If `kind` is `TextAnalytics` this specifies the key of the Search service."
  sensitive   = true
}

variable "cognitive_account_custom_subdomain_name" {
  type        = string
  default     = null
  description = "(Optional) The subdomain name used for token-based authentication. This property is required when `network_acls` is specified. Changing this forces a new resource to be created."
}

variable "cognitive_account_customer_managed_key" {
  type = object({
    identity_client_id = optional(string)
    key_vault_key_id   = string
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
  default     = null
  description = <<-DESCRIPTION
 - `identity_client_id` - (Optional) The Client ID of the User Assigned Identity that has access to the key. This property only needs to be specified when there're multiple identities attached to the Cognitive Account.
 - `key_vault_key_id` - (Required) The ID of the Key Vault Key which should be used to Encrypt the data in this Cognitive Account.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Cognitive Account Customer Managed Key.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Cognitive Account Customer Managed Key.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Cognitive Account Customer Managed Key.
 - `update` - (Defaults to 30 minutes) Used when updating the Cognitive Account Customer Managed Key.
DESCRIPTION
}

variable "cognitive_account_dynamic_throttling_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Whether to enable the dynamic throttling for this Cognitive Service Account."
}

variable "cognitive_account_fqdns" {
  type        = list(string)
  default     = null
  description = "(Optional) List of FQDNs allowed for the Cognitive Account."
}

variable "cognitive_account_identity" {
  type = object({
    identity_ids = optional(set(string))
    type         = string
  })
  default     = null
  description = <<-DESCRIPTION
 - `identity_ids` - (Optional) Specifies a list of User Assigned Managed Identity IDs to be assigned to this Cognitive Account.
 - `type` - (Required) Specifies the type of Managed Service Identity that should be configured on this Cognitive Account. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both).
DESCRIPTION
}

variable "cognitive_account_local_auth_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Whether local authentication methods is enabled for the Cognitive Account. Defaults to `true`."
}

variable "cognitive_account_metrics_advisor_aad_client_id" {
  type        = string
  default     = null
  description = "(Optional) The Azure AD Client ID (Application ID). This attribute is only set when kind is `MetricsAdvisor`. Changing this forces a new resource to be created."
}

variable "cognitive_account_metrics_advisor_aad_tenant_id" {
  type        = string
  default     = null
  description = "(Optional) The Azure AD Tenant ID. This attribute is only set when kind is `MetricsAdvisor`. Changing this forces a new resource to be created."
}

variable "cognitive_account_metrics_advisor_super_user_name" {
  type        = string
  default     = null
  description = "(Optional) The super user of Metrics Advisor. This attribute is only set when kind is `MetricsAdvisor`. Changing this forces a new resource to be created."
}

variable "cognitive_account_metrics_advisor_website_name" {
  type        = string
  default     = null
  description = "(Optional) The website name of Metrics Advisor. This attribute is only set when kind is `MetricsAdvisor`. Changing this forces a new resource to be created."
}

variable "cognitive_account_network_acls" {
  type = object({
    default_action = string
    ip_rules       = optional(set(string))
    virtual_network_rules = optional(set(object({
      ignore_missing_vnet_service_endpoint = optional(bool)
      subnet_id                            = string
    })))
  })
  default     = null
  description = <<-DESCRIPTION
 - `default_action` - (Required) The Default Action to use when no rules match from `ip_rules` / `virtual_network_rules`. Possible values are `Allow` and `Deny`.
 - `ip_rules` - (Optional) One or more IP Addresses, or CIDR Blocks which should be able to access the Cognitive Account.

 ---
 `virtual_network_rules` block supports the following:
 - `ignore_missing_vnet_service_endpoint` - (Optional) Whether ignore missing vnet service endpoint or not. Default to `false`.
 - `subnet_id` - (Required) The ID of the subnet which should be able to access this Cognitive Account.
DESCRIPTION
}

variable "cognitive_account_outbound_network_access_restricted" {
  type        = bool
  default     = null
  description = "(Optional) Whether outbound network access is restricted for the Cognitive Account. Defaults to `false`."
}

variable "cognitive_account_public_network_access_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Whether public network access is allowed for the Cognitive Account. Defaults to `true`."
}

variable "cognitive_account_qna_runtime_endpoint" {
  type        = string
  default     = null
  description = "(Optional) A URL to link a QnAMaker cognitive account to a QnA runtime."
}

variable "cognitive_account_storage" {
  type = list(object({
    identity_client_id = optional(string)
    storage_account_id = string
  }))
  default     = null
  description = <<-DESCRIPTION
 - `identity_client_id` - (Optional) The client ID of the managed identity associated with the storage resource.
 - `storage_account_id` - (Required) Full resource id of a Microsoft.Storage resource.
DESCRIPTION
}

variable "cognitive_account_tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags to assign to the resource."
}

variable "cognitive_account_timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-DESCRIPTION
 - `create` - (Defaults to 30 minutes) Used when creating the Cognitive Service Account.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Cognitive Service Account.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Cognitive Service Account.
 - `update` - (Defaults to 30 minutes) Used when updating the Cognitive Service Account.
DESCRIPTION
}

variable "cognitive_deployments" {
  type = map(object({
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
  default     = {}
  description = <<-DESCRIPTION
 - `name` - (Required) The name of the Cognitive Services Account Deployment. Changing this forces a new resource to be created.
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
DESCRIPTION
  nullable    = false
}

variable "green_field_private_dns_zone" {
  type = object({
    resource_group_name = string
    tags                = optional(map(string))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
  default     = null
  description = <<-DESCRIPTION
 An object that represents the Private DNS Zone you'd like to create in this module.
 - `resource_group_name` - (Required) Specifies the resource group where the resource exists. Changing this forces a new resource to be created.
 - `tags` - (Optional) A mapping of tags to assign to the resource.
 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Private DNS Zone.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Private DNS Zone.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Private DNS Zone.
 - `update` - (Defaults to 30 minutes) Used when updating the Private DNS Zone.
DESCRIPTION
}

variable "pe_subresource_names" {
  type        = list(string)
  default     = ["account"]
  description = "A list of subresource names which the Private Endpoint is able to connect to. `subresource_names` corresponds to `group_id`. Possible values are detailed in the product [documentation](https://docs.microsoft.com/azure/private-link/private-endpoint-overview#private-link-resource) in the `Subresources` column. Changing this forces a new resource to be created."
}

variable "private_endpoint" {
  type = map(object({
    name                            = string
    vnet_key                        = string
    subnet_key                      = string
    resource_group_name             = optional(string)
    private_dns_entry_enabled       = optional(bool, false)
    private_service_connection_name = optional(string, "privateserviceconnection")
    is_manual_connection            = optional(bool, false)
    tags                            = optional(map(string), {})
  }))
  default     = {}
  description = <<-DESCRIPTION
  A map of objects that represent the configuration for a private endpoint."
  type = map(object({
    name                               = (Required) Specifies the Name of the Private Endpoint. Changing this forces a new resource to be created.
    vnet_key                           = (Required) Map key of the virtual network in `var.private_endpoint_subnets` where the Private Endpoint's exists. Changing this forces a new resource to be created.
    subnet_key                         = (Required) Map key of the `subnets` in `var.private_endpoint_subnets` where the subnet that this Private IP Addresses will be created in. Changing this forces a new resource to be created.
    resource_group_name                = (Optional) Specifies the Name of the Resource Group within which the Private Endpoint should exist. Omit this field would use cognitive account's resource group name. Changing this forces a new resource to be created.
    dns_zone_virtual_network_link_name = (Optional) The name of the Private DNS Zone Virtual Network Link. Changing this forces a new resource to be created. Default to `dns_zone_link`.
    private_dns_entry_enabled          = (Optional) Whether or not to create a `private_dns_zone_group` block for the Private Endpoint. Default to `false`.
    private_service_connection_name    = (Optional) Specifies the Name of the Private Service Connection. Changing this forces a new resource to be created. Default to `privateserviceconnection`.
    is_manual_connection               = (Optional) Does the Private Endpoint require Manual Approval from the remote resource owner? Changing this forces a new resource to be created. Default to `false`.
    tags                               = (Optional) A mapping of tags to assign to the resource.
  }))
DESCRIPTION
  nullable    = false
}

variable "private_endpoint_subnets" {
  type = map(object({
    vnet_id                 = string
    vnet_dns_zone_link_name = optional(string)
    vnet_dns_zone_link_tags = optional(map(string), {})
    subnets = map(object({
      id = string
    }))
  }))
  default     = {}
  description = <<-DESCRIPTION
  Please be advised! We won't try to create `azurerm_private_dns_zone_virtual_network_link` if `var.green_field_private_dns_zone`. If you're using brown field private dns zone, you need link the private dns zone with the virtual network yourself.
  A map of objects that represent the virtual networks and subnets for private endpoints.
  Map's key must be a static literal value.
  type = map(object({
    vnet_id = The Virtual Network's ID which private endpoint is created in. Changing this forces a new resource to be created.
    vnet_dns_zone_link_name = The name of the Private DNS Zone Virtual Network Link. Defaults to "<Private Dns Zone Name>-<VNet Key>". Changing this forces a new resource to be created.
    vnet_dns_zone_link_tags = (Optional) A mapping of tags to assign to the `azurerm_private_dns_zone_virtual_network_link` resource. Changing this forces a new resource to be created.
    subnets = map(object({
      id = The Subnet's ID which private endpoint is created in. Changing this forces a new resource to be created.
    }))
  }))
DESCRIPTION

  validation {
    condition     = alltrue([for k, v in var.private_endpoint_subnets : alltrue([for sk, subnet in v.subnets : startswith(subnet.id, v.vnet_id)])])
    error_message = "`id` in `subnets` must belongs to the virtual network that `vnet_id` represents."
  }
}
