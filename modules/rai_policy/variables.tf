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

variable "cognitive_account_id" {
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
