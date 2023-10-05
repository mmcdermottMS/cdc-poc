variable "rg_name" {
  type        = string
  description = "Name of the resource group to deploy the resource to."
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "vnet_name" {
  type        = string
  description = "Name of the VNET."
}

variable "zone_name" {
  type        = string
  description = "Private DNS Zone FQDN."
}
