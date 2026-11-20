variable "ignore_body_changes" {
  type = object({
    cognitiveservices_accounts_projects_connections = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative dot paths ignored on the connection. Ignored configuration is not sent to Azure; changes take effect only after apply.

- `cognitiveservices_accounts_projects_connections` - Connection body paths. Defaults to `[]` (send all properties). Ignore whole lists, not individual indices.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    cognitiveservices_accounts_projects_connections = optional(string, "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions owned by this submodule.

- `cognitiveservices_accounts_projects_connections` - Project connection type and API version. The preview default follows Microsoft's APIM connection sample; the ApiManagement/ProjectManagedIdentity contract is absent from the published schema.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string), ["IfMatchPreconditionFailed", "RequestConflict", "CannotDeleteResource", "provisioning state is not terminal", "nested resources exist"])
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = {}
  description = <<DESCRIPTION
Retry configuration for the connection.

- `error_message_regex` - Patterns matching errors to retry.
- `interval_seconds` - Initial retry interval in seconds.
- `max_interval_seconds` - Maximum retry interval in seconds.
DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string, "90m")
    read   = optional(string, "5m")
    update = optional(string, "90m")
    delete = optional(string, "90m")
  })
  default     = {}
  description = <<DESCRIPTION
Connection operation timeouts. Set to null to use provider defaults.

- `create` - Create timeout.
- `read` - Read timeout.
- `update` - Update timeout.
- `delete` - Delete timeout.
DESCRIPTION
}
