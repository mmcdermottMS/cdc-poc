variable "location" {
  type        = string
  description = "Deployment region (ex. East US), for supported regions see https://docs.microsoft.com/en-us/azure/spring-apps/faq?pivots=programming-language-java#in-which-regions-is-azure-spring-apps-basicstandard-tier-available"
}

variable "resource_prefix" {
  type        = string
  description = "Name of the resource prefix."
}

variable "rg_name" {
  type        = string
  description = "Name of the resource group to deploy the resource to."
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "vnet_addr_prefix" {
  type = string
}

variable "vnet_name" {
  type        = string
  description = "Name of the VNET."
}
