variable "location" {
  type        = string
  default     = "eastus"
  description = "The location/region where the cognitive service account is created. Changing this forces a new resource to be created."
}

variable "enable_telemetry" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}
