variable "location" {
  type        = string
  default     = "eastus"
  description = "The location/region where the cognitive service account is created. Changing this forces a new resource to be created."
}

variable "resource_group_name" {
  description = "Specifies the name of the Resource Group in which the Virtual Machine should exist"
  type        = string
  default     = "default"
}