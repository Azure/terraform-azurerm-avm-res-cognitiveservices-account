variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Whether to enable the connection submodule's deployment telemetry."
  nullable    = false
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region for the example resources and deployment telemetry. Must support AIServices projects, APIM Premium in availability zones 1 and 2, and the selected GlobalStandard models."
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
  description = "Static catalog keyed by gateway deployment alias. The example deploys these OpenAI models with GlobalStandard capacity 1."
  nullable    = false
}

variable "name" {
  type        = string
  default     = "enterprise-models"
  description = "Name of the new connection. Choose a name not already owned by another Terraform configuration."
  nullable    = false
}
