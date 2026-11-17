variable "audience" {
  type        = string
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. Entra token-acquisition resource URI for the gateway (api:// or https://), not a JWT audience GUID or a /.default scope."
  nullable    = false

  validation {
    condition     = can(regex("^(api|https)://[^\\s?#]+$", var.audience)) && !endswith(lower(var.audience), "/.default")
    error_message = "audience must be an api:// or https:// token resource URI without whitespace, query or fragment, and must not end in /.default."
  }
}

variable "models" {
  type = map(object({
    model_name    = string
    model_version = optional(string, "")
  }))
  description = <<DESCRIPTION
THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION.

Static models keyed by the gateway deployment name accepted in the request body.

- `model_name` - Nonblank underlying model name.
- `model_version` - Optional underlying model version; defaults to an empty string.

At least one model is required. Agents select connectionName/gatewayDeploymentName, not the underlying model name.
DESCRIPTION
  nullable    = false

  validation {
    condition = length(var.models) > 0 && alltrue([
      for deployment_name, model in var.models :
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*$", deployment_name)) && try(length(trimspace(model.model_name)) > 0, false)
    ])
    error_message = "models must contain at least one deployment with an alphanumeric initial character followed by alphanumeric, dot, underscore or hyphen characters, and a nonblank model_name."
  }
}

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
  description = "THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION. HTTPS OpenAI Chat Completions base URL without credentials, query, fragment, trailing slash, deployment path or operation. Verify the actual runtime URL separately."
  nullable    = false

  validation {
    condition = (
      can(regex("^https://[a-zA-Z0-9.-]+(:443)?(/[a-zA-Z0-9._~-]+)*$", var.target)) &&
      !can(regex("(?i)/(chat/completions|responses|deployments)(/|$)", var.target))
    )
    error_message = "target must be an HTTPS base URL without credentials, query, fragment, trailing slash, deployment path or inference operation."
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

variable "location" {
  type        = string
  default     = null
  description = "Azure region for the module's telemetry deployment. May be null only when telemetry is disabled."

  validation {
    condition     = !var.enable_telemetry || var.location != null
    error_message = "location must not be null when telemetry is enabled."
  }
}
