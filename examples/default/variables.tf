variable "location" {
  type    = string
  default = "East US"
}

variable "resource_group_name" {
  description = "Specifies the name of the Resource Group in which the Virtual Machine should exist"
  type        = string
  default     = "default"
}