variable "name" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Project connection name: 3-33 alphanumeric, underscore or hyphen characters, starting with an alphanumeric character."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{2,32}$", var.name))
    error_message = "name must be 3-33 alphanumeric, underscore or hyphen characters, starting with an alphanumeric character."
  }
}

variable "parent_id" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. ARM resource ID of the existing Microsoft.CognitiveServices/accounts/projects project that owns the connection."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.CognitiveServices/accounts/projects", var.parent_id))
    error_message = "parent_id must be a valid Cognitive Services project resource ID."
  }
}

variable "target" {
  type        = string
  description = "Connection target required by the selected service, without embedded credentials. For ApiManagement this must be an HTTPS Chat Completions base URL without query, fragment, trailing slash, deployment path or operation. Other ARM categories accept service-specific targets, not necessarily HTTPS URLs."
  nullable    = false

  validation {
    condition = var.category != "ApiManagement" ? length(trimspace(var.target)) > 0 : (
      can(regex("^https://[a-zA-Z0-9.-]+(:443)?(/[a-zA-Z0-9._~-]+)*$", var.target)) &&
      !can(regex("(?i)/(chat/completions|responses|deployments)(/|$)", var.target))
    )
    error_message = "target must be an HTTPS base URL without credentials, query, fragment, trailing slash, deployment path or inference operation."
  }
}

variable "audience" {
  type        = string
  default     = null
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Entra token-acquisition resource URI for the gateway (api:// or https://), not a JWT audience GUID or a /.default scope."

  validation {
    condition     = var.audience == null ? var.category != "ApiManagement" : can(regex("^(api|https)://[^\\s?#]+$", var.audience)) && !endswith(lower(var.audience), "/.default")
    error_message = "audience must be an api:// or https:// token resource URI without whitespace, query or fragment, and must not end in /.default."
  }
  validation {
    condition     = var.category == "ApiManagement" || var.audience == null
    error_message = "audience is an APIM-specific property; omit it for other categories."
  }
}

variable "auth_type" {
  type        = string
  default     = "ProjectManagedIdentity"
  description = "ARM authentication discriminator. Defaults to ProjectManagedIdentity; at authoring time, only ApiManagement is known to support it, but the module does not restrict it by category. Other values are AAD, AccessKey, AccountKey, ApiKey, CustomKeys, ManagedIdentity, None, OAuth2, PAT, SAS, ServicePrincipal and UsernamePassword. Verify service support for the selected category; accepting a value is not proof of runtime support."
  nullable    = false

  validation {
    condition     = contains(keys(local.credential_fields), var.auth_type)
    error_message = "auth_type must be a documented ARM connection authentication type or ProjectManagedIdentity."
  }
}

variable "category" {
  type        = string
  default     = "ApiManagement"
  description = "Case-sensitive ARM connection category; any nonblank value is accepted. Known categories at authoring time are documented by the 2025-04-01-preview ARM reference, plus Foundry's ApiManagement and AzureStorageAccount extensions. Examples include AzureOpenAI, AIServices, CognitiveSearch, AzureBlob, CosmosDb, OpenAI, ApiKey, CustomKeys, Git and ContainerRegistry. Other categories use the common body and caller metadata; verify support and required properties for the selected service and API version."
  nullable    = false

  validation {
    condition     = length(trimspace(var.category)) > 0
    error_message = "category must not be blank."
  }
}

variable "credentials" {
  type        = map(string)
  default     = {}
  description = <<DESCRIPTION
Sensitive, ephemeral credentials using exact ARM field names. Passed only through AzAPI's write-only sensitive_body; never put secrets in metadata or target. Defaults to empty.

- AAD, None, ProjectManagedIdentity: no entries.
- ApiKey, AccountKey: key.
- AccessKey: accessKeyId and secretAccessKey.
- ManagedIdentity: optional clientId and resourceId of a user-assigned managed identity.
- OAuth2: clientId and clientSecret; optional authUrl, developerToken, password, refreshToken, tenantId, username as required by the service.
- PAT: pat. SAS: sas.
- ServicePrincipal: clientId, clientSecret and tenantId.
- UsernamePassword: username and password; optional securityToken.
- CustomKeys: arbitrary nonempty key/value entries, wrapped as credentials.keys.

Supply at plan and apply, and increment credentials_version when rotating or changing credentials. Category-specific authentication and authorization remain the caller's responsibility.
DESCRIPTION
  nullable    = false
  sensitive   = true
  ephemeral   = true

  validation {
    condition = contains(keys(local.credential_fields), var.auth_type) ? (
      var.auth_type == "CustomKeys" ? length(var.credentials) > 0 : (
        alltrue([for field in local.credential_fields[var.auth_type].required : contains(keys(var.credentials), field)]) &&
        alltrue([for field in keys(var.credentials) : contains(concat(local.credential_fields[var.auth_type].required, local.credential_fields[var.auth_type].optional), field)])
      )
    ) : true
    error_message = "credentials must contain the required ARM fields for auth_type and no unsupported fields."
  }
  validation {
    condition     = alltrue([for value in values(var.credentials) : try(length(trimspace(value)) > 0, false)])
    error_message = "Credential values must not be null or blank."
  }
  validation {
    condition     = var.auth_type != "OAuth2" || alltrue([for field in lookup(local.oauth2_category_fields, var.category, []) : contains(keys(var.credentials), field)])
    error_message = "OAuth2 credentials must also include the category-specific fields documented by ARM (for example refreshToken, tenantId or authUrl)."
  }
  validation {
    condition     = var.auth_type != "ManagedIdentity" || !contains(keys(var.credentials), "resourceId") ? true : can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", var.credentials["resourceId"]))
    error_message = "ManagedIdentity resourceId must be a valid user-assigned managed identity resource ID."
  }
}

variable "credentials_version" {
  type        = string
  default     = "1"
  description = "Nonsecret credential revision. Change this value whenever credentials change so AzAPI sends the write-only credentials on update. The revision is stored in state; credentials are not."
  nullable    = false

  validation {
    condition     = length(trimspace(var.credentials_version)) > 0
    error_message = "credentials_version must not be blank."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "is_shared_to_all" {
  type        = bool
  default     = null
  description = "Optional ARM isSharedToAll override. Null preserves category behavior: ApiManagement explicitly sends false; other categories omit the property and leave sharing to the API. This does not grant service access or configure identities."
}

variable "location" {
  type        = string
  default     = null
  description = "Azure region for the module's telemetry deployment. May be null only when telemetry is disabled."

  validation {
    condition     = !var.enable_telemetry || var.location != null
    error_message = "location must not be null when telemetry is enabled."
  }
}

variable "metadata" {
  type        = map(string)
  default     = {}
  description = "Nonsecret service-specific ARM metadata. AzureStorageAccount, CosmosDb and CognitiveSearch default ApiType to Azure; pass ResourceId and location as needed for the target, plus ApiVersion for Search when required. Values are strings; JSON-encode structured metadata. APIM reserves models and deploymentInPath for its typed catalog inputs. Metadata is persisted in state and must not contain credentials."
  nullable    = false

  validation {
    condition     = var.category != "ApiManagement" || length(setintersection(toset(keys(var.metadata)), toset(["models", "deploymentInPath"]))) == 0
    error_message = "Use models for the APIM catalog; metadata must not override models or deploymentInPath."
  }
  validation {
    condition     = var.category != "AzureStorageAccount" || !contains(keys(var.metadata), "ResourceId") ? true : can(provider::azapi::parse_resource_id("Microsoft.Storage/storageAccounts", var.metadata["ResourceId"]))
    error_message = "AzureStorageAccount metadata.ResourceId must be a valid storage account resource ID."
  }
  validation {
    condition     = var.category != "CosmosDb" || !contains(keys(var.metadata), "ResourceId") ? true : can(provider::azapi::parse_resource_id("Microsoft.DocumentDB/databaseAccounts", var.metadata["ResourceId"]))
    error_message = "CosmosDb metadata.ResourceId must be a valid Cosmos DB database account resource ID."
  }
  validation {
    condition     = var.category != "CognitiveSearch" || !contains(keys(var.metadata), "ResourceId") ? true : can(provider::azapi::parse_resource_id("Microsoft.Search/searchServices", var.metadata["ResourceId"]))
    error_message = "CognitiveSearch metadata.ResourceId must be a valid Search service resource ID."
  }
}

variable "models" {
  type = map(object({
    model_name    = string
    model_version = optional(string, "")
    model_format  = optional(string, "OpenAI")
  }))
  default     = {}
  description = <<DESCRIPTION
THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION.

Static models keyed by the gateway deployment name accepted in the request body.

- `model_name` - Nonblank underlying model name.
- `model_version` - Optional underlying model version; defaults to an empty string.
- `model_format` - Model provider format; defaults to OpenAI.

At least one model is required for ApiManagement; omit models for other categories. Agents select connectionName/gatewayDeploymentName, not the underlying model name.
DESCRIPTION
  nullable    = false

  validation {
    condition = (var.category == "ApiManagement" ? length(var.models) > 0 : length(var.models) == 0) && alltrue([
      for deployment_name, model in var.models :
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*$", deployment_name)) && try(length(trimspace(model.model_name)) > 0, false) && length(trimspace(model.model_format)) > 0
    ])
    error_message = "ApiManagement requires at least one model with a valid deployment alias and nonblank model_name/model_format; other categories must omit models."
  }
}
