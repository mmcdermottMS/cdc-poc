variable "dnz_zone_id" {
  type        = string
  description = "ID of the Private DNS Zone to associate with the private endpoint."
}

variable "dns_zone_name" {
  type        = string
  description = "Private DNS Zone name to associate with the private endpoint."
}

variable "location" {
  type        = string
  description = "Deployment region (ex. East US), for supported regions see https://docs.microsoft.com/en-us/azure/spring-apps/faq?pivots=programming-language-java#in-which-regions-is-azure-spring-apps-basicstandard-tier-available"
}

variable "name" {
  type        = string
  description = "Name of the Key Vault instance."
}

variable "resource_id" {
  type        = string
  description = "ID of the resource to associate with the private endpoint."
}

variable "resource_name" {
  type        = string
  description = "Name of the resource type to associate with the private endpoint."
}

variable "rg_name" {
  type        = string
  description = "Name of the resource group to deploy the resource to."
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet to deploy the private endpoint to."
}

variable "tags" {
  type    = map(any)
  default = {}
}
