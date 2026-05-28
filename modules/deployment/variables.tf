variable "model" {
  type = object({
    format  = string
    name    = string
    version = optional(string)
  })
  description = <<-DESCRIPTION
 - `format`  - (Required) The format of the Cognitive Services Account Deployment model. Possible value is `OpenAI`.
 - `name`    - (Required) The name of the Cognitive Services Account Deployment model.
 - `version` - (Optional) The version of Cognitive Services Account Deployment model.
DESCRIPTION
  nullable    = false
}

variable "name" {
  type        = string
  description = "(Required) The name of the Cognitive Services Account Deployment. Changing this forces a new resource to be created."
  nullable    = false
}

variable "parent_id" {
  type        = string
  description = "(Required) The resource ID of the parent Cognitive Services Account that owns this deployment."
  nullable    = false
}

variable "scale" {
  type = object({
    capacity = optional(number, 1)
    family   = optional(string)
    size     = optional(string)
    tier     = optional(string)
    type     = string
  })
  description = <<-DESCRIPTION
 - `type`     - (Required) The name of the SKU.
 - `capacity` - (Optional) Tokens-per-Minute (TPM). Defaults to `1`.
 - `family`   - (Optional) Hardware generation, for the same SKU.
 - `size`     - (Optional) The SKU size.
 - `tier`     - (Optional) Possible values are `Free`, `Basic`, `Standard`, `Premium`, `Enterprise`.
DESCRIPTION
  nullable    = false
}

variable "dynamic_throttling_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Whether dynamic throttling is enabled. Defaults to `false`."
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

variable "lock_id" {
  type        = string
  default     = null
  description = "(Optional) Resource ID used as a mutex to serialize deployment operations. When set, the parent Cognitive Services Account ID is typically used so AzAPI serializes create/update operations across sibling deployments."
}

variable "rai_policy_name" {
  type        = string
  default     = null
  description = "(Optional) The name of the RAI policy associated with the deployment."
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
Per-operation timeouts for the deployment resource. Defaults to `null` (provider defaults). Each value is a Go duration string (e.g. `30m`, `1h`).
DESCRIPTION
}

variable "version_upgrade_option" {
  type        = string
  default     = "OnceNewDefaultVersionAvailable"
  description = "(Optional) Deployment model version upgrade option. Possible values are `OnceNewDefaultVersionAvailable`, `OnceCurrentVersionExpired`, and `NoAutoUpgrade`. Defaults to `OnceNewDefaultVersionAvailable`."
}
