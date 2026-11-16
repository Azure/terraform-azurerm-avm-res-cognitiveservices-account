variable "audience" {
  type        = string
  nullable    = false
  description = "The existing gateway's Entra token resource URI, for example api://gateway; not a /.default scope."
}

variable "parent_id" {
  type        = string
  nullable    = false
  description = "The ARM ID of the existing Foundry project whose identity is authorized to call the gateway."

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.CognitiveServices/accounts/projects", var.parent_id))
    error_message = "parent_id must be a valid Cognitive Services project resource ID."
  }
}

variable "target" {
  type        = string
  nullable    = false
  description = "The existing gateway's HTTPS Chat Completions base URL, without a trailing slash, operation path, query or fragment."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  nullable    = false
  description = "Whether to enable the connection submodule's deployment telemetry."
}

variable "location" {
  type        = string
  default     = "eastus"
  nullable    = false
  description = "Azure region for deployment telemetry; does not change the existing project's location."
}

variable "models" {
  type = map(object({
    model_name    = string
    model_version = optional(string, "")
  }))
  default = {
    chat = {
      model_name    = "gpt-4.1"
      model_version = "2025-04-14"
    }
  }
  nullable    = false
  description = "Static catalog keyed by gateway deployment alias. Each value supplies model_name and optional model_version. Must match routes configured by the gateway owner; this does not publish routes."
}

variable "name" {
  type        = string
  default     = "enterprise-models"
  nullable    = false
  description = "Name of the new connection. Choose a name not already owned by another Terraform configuration."
}
