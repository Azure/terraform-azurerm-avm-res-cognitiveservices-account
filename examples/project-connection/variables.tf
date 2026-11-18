variable "audience" {
  type        = string
  default     = null
  description = "The existing gateway's Entra token resource URI, not a /.default scope. Supply together with parent_id and target, or leave all three null to provision isolated test prerequisites."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Whether to enable the connection submodule's deployment telemetry."
  nullable    = false
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region for test prerequisites and deployment telemetry; does not change an externally supplied project's location. Must support AIServices projects, APIM Consumption and the selected GlobalStandard models."
  nullable    = false
}

variable "models" {
  type = map(object({
    model_name    = string
    model_version = optional(string, "")
  }))
  default = {
    chat = {
      model_name    = "gpt-4.1-mini"
      model_version = "2025-04-14"
    }
  }
  description = "Static catalog keyed by gateway deployment alias. The isolated fixture deploys these OpenAI models with GlobalStandard capacity 1. With external inputs, aliases must match routes configured by the gateway owner; the connection does not publish routes."
  nullable    = false
}

variable "name" {
  type        = string
  default     = "enterprise-models"
  description = "Name of the new connection. Choose a name not already owned by another Terraform configuration."
  nullable    = false
}

variable "parent_id" {
  type        = string
  default     = null
  description = "The ARM ID of an existing Foundry project whose identity is authorized to call the gateway. Supply together with audience and target, or leave all three null to provision isolated test prerequisites."

  validation {
    condition     = var.parent_id == null ? true : can(provider::azapi::parse_resource_id("Microsoft.CognitiveServices/accounts/projects", var.parent_id))
    error_message = "parent_id must be a valid Cognitive Services project resource ID."
  }
  validation {
    condition = (
      (var.parent_id == null && var.target == null && var.audience == null) ||
      (var.parent_id != null && var.target != null && var.audience != null)
    )
    error_message = "Supply parent_id, target and audience together for existing infrastructure, or leave all three null to provision isolated test prerequisites."
  }
}

variable "target" {
  type        = string
  default     = null
  description = "The existing gateway's HTTPS Chat Completions base URL, without a trailing slash, operation path, query or fragment. Supply together with parent_id and audience, or leave all three null to provision isolated test prerequisites."
}
