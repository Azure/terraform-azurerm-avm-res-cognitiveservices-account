variable "base_policy_name" {
  type        = string
  description = "(Required) The name of the base policy."
  nullable    = false
}

variable "mode" {
  type        = string
  description = "(Required) RAI policy mode. The enum value mapping is `Default`, `Deferred`, `Blocking`, `Asynchronous_filter`. Use `Asynchronous_filter` for API versions after 2024-10-01."
  nullable    = false
}

variable "name" {
  type        = string
  description = "(Required) The name of the RAI policy. Changing this forces a new resource to be created."
  nullable    = false
}

variable "parent_id" {
  type        = string
  description = "(Required) The resource ID of the parent Cognitive Services / AI Services account that owns this RAI policy."
  nullable    = false
}

variable "content_filters" {
  type = list(object({
    blocking           = bool
    enabled            = bool
    name               = string
    severity_threshold = string
    source             = string
  }))
  default     = null
  description = <<-DESCRIPTION
 `content_filters` block supports the following:
 - `name`               - (Required) Name of ContentFilter.
 - `enabled`            - (Required) If the ContentFilter is enabled.
 - `severity_threshold` - (Required) Level at which content is filtered. Possible values are `Low`, `Medium`, `High`.
 - `blocking`           - (Required) If blocking would occur.
 - `source`             - (Required) Content source to apply the Content Filters. Possible values are `Prompt`, `Completion`.
DESCRIPTION
}

variable "custom_block_lists" {
  type = list(object({
    source          = string
    block_list_name = string
    blocking        = bool
  }))
  default     = null
  description = <<-DESCRIPTION
 `custom_block_lists` block supports the following:
 - `source`          - (Required) Content source to apply the Custom Block Lists. Possible values are `Prompt`, `Completion`.
 - `block_list_name` - (Required) Name of ContentFilter.
 - `blocking`        - (Required) If blocking would occur.
DESCRIPTION
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the submodule.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
    multiplier           = optional(number)
    randomization_factor = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to the `azapi_resource` managed by this submodule. Defaults to `null` (no custom retry).

- `error_message_regex`  - (Optional) A list of regex patterns matching error messages that trigger a retry.
- `interval_seconds`     - (Optional) Initial interval between retries in seconds.
- `max_interval_seconds` - (Optional) Maximum interval between retries in seconds.
- `multiplier`           - (Optional) The multiplier applied to the retry interval after each attempt.
- `randomization_factor` - (Optional) The randomization factor applied to the retry interval.

See <https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource#retry> for full semantics.
DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Per-operation timeouts for the RAI policy resource. Defaults to `null` (provider defaults). Each value is a Go duration string (e.g. `30m`, `1h`).
DESCRIPTION
}
