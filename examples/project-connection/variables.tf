variable "audience" {
  type        = string
  default     = "api://gateway"
  description = "The existing gateway's Entra token resource URI, not a /.default scope. The default is a planning placeholder; replace it before deployment."
  nullable    = false
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
  description = "Azure region for deployment telemetry; does not change the existing project's location."
  nullable    = false
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
  description = "Static catalog keyed by gateway deployment alias. Each value supplies model_name and optional model_version. Must match routes configured by the gateway owner; this does not publish routes."
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
  default     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.CognitiveServices/accounts/example-foundry/projects/research"
  description = "The ARM ID of the existing Foundry project whose identity is authorized to call the gateway. The default is a planning placeholder; replace it before deployment."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.CognitiveServices/accounts/projects", var.parent_id))
    error_message = "parent_id must be a valid Cognitive Services project resource ID."
  }
}

variable "target" {
  type        = string
  default     = "https://gateway.example.com/ai/v1"
  description = "The existing gateway's HTTPS Chat Completions base URL, without a trailing slash, operation path, query or fragment. The default is a planning placeholder; replace it before deployment."
  nullable    = false
}
