variable "kind" {
  type        = string
  description = "(Required) Specifies the type of Cognitive Service Account that should be created. Possible values are `Academic`, `AnomalyDetector`, `Bing.Autosuggest`, `Bing.Autosuggest.v7`, `Bing.CustomSearch`, `Bing.Search`, `Bing.Search.v7`, `Bing.Speech`, `Bing.SpellCheck`, `Bing.SpellCheck.v7`, `CognitiveServices`, `ComputerVision`, `ContentModerator`, `ContentSafety`, `CustomSpeech`, `CustomVision.Prediction`, `CustomVision.Training`, `Emotion`, `Face`, `FormRecognizer`, `ImmersiveReader`, `LUIS`, `LUIS.Authoring`, `MetricsAdvisor`, `OpenAI`, `Personalizer`, `QnAMaker`, `Recommendations`, `SpeakerRecognition`, `Speech`, `SpeechServices`, `SpeechTranslation`, `TextAnalytics`, `TextTranslation` and `WebLM`. Changing this forces a new resource to be created."
  nullable    = false
}

variable "location" {
  type        = string
  description = "(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  nullable    = false
}

variable "name" {
  type        = string
  description = "(Required) Specifies the name of the Cognitive Service Account. Changing this forces a new resource to be created."
  nullable    = false
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which the Cognitive Service Account is created. Changing this forces a new resource to be created."
  nullable    = false
}

variable "sku_name" {
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

variable "custom_question_answering_search_service_id" {
  type        = string
  default     = null
  description = "(Optional) If `kind` is `TextAnalytics` this specifies the ID of the Search service."
}

variable "custom_question_answering_search_service_key" {
  type        = string
  default     = null
  description = "(Optional) If `kind` is `TextAnalytics` this specifies the key of the Search service."
  sensitive   = true
}

variable "custom_subdomain_name" {
  type        = string
  default     = null
  description = "(Optional) The subdomain name used for token-based authentication. This property is required when `network_acls` is specified. Changing this forces a new resource to be created."
}

variable "customer_managed_key" {
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

variable "dynamic_throttling_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Whether to enable the dynamic throttling for this Cognitive Service Account."
}

variable "fqdns" {
  type        = list(string)
  default     = null
  description = "(Optional) List of FQDNs allowed for the Cognitive Account."
}

variable "identity" {
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

variable "local_auth_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Whether local authentication methods is enabled for the Cognitive Account. Defaults to `true`."
}

variable "metrics_advisor_aad_client_id" {
  type        = string
  default     = null
  description = "(Optional) The Azure AD Client ID (Application ID). This attribute is only set when kind is `MetricsAdvisor`. Changing this forces a new resource to be created."
}

variable "metrics_advisor_aad_tenant_id" {
  type        = string
  default     = null
  description = "(Optional) The Azure AD Tenant ID. This attribute is only set when kind is `MetricsAdvisor`. Changing this forces a new resource to be created."
}

variable "metrics_advisor_super_user_name" {
  type        = string
  default     = null
  description = "(Optional) The super user of Metrics Advisor. This attribute is only set when kind is `MetricsAdvisor`. Changing this forces a new resource to be created."
}

variable "metrics_advisor_website_name" {
  type        = string
  default     = null
  description = "(Optional) The website name of Metrics Advisor. This attribute is only set when kind is `MetricsAdvisor`. Changing this forces a new resource to be created."
}

variable "network_acls" {
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

variable "outbound_network_access_restricted" {
  type        = bool
  default     = null
  description = "(Optional) Whether outbound network access is restricted for the Cognitive Account. Defaults to `false`."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Whether public network access is allowed for the Cognitive Account. Defaults to `true`."
}

variable "qna_runtime_endpoint" {
  type        = string
  default     = null
  description = "(Optional) A URL to link a QnAMaker cognitive account to a QnA runtime."
}

variable "storage" {
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

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags to assign to the resource."
}

variable "timeouts" {
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

variable "private_endpoints" {
  type = map(object({
    name               = optional(string, null)
    role_assignments   = optional(map(object({})), {}) # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#role-assignments
    lock               = optional(object({}), {})      # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#resource-locks
    tags               = optional(map(any), null)      # see https://azure.github.io/Azure-Verified-Modules/Azure-Verified-Modules/specs/shared/interfaces/#tags
    subnet_resource_id = string

    resource_group_name             = optional(string)
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<-DESCRIPTION
  A map of private endpoints to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
  - `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
  - `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
  - `tags` - (Optional) A mapping of tags to assign to the private endpoint.
  - `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
  - `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
  - `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
  - `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
  - `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
  - `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
  - `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the Key Vault.
  - `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
    - `name` - The name of the IP configuration.
    - `private_ip_address` - The private IP address of the IP configuration.
  DESCRIPTION
  nullable    = false
}