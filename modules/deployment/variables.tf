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

variable "cognitive_account_id" {
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

variable "rai_policy_name" {
  type        = string
  default     = null
  description = "(Optional) The name of the RAI policy associated with the deployment."
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
