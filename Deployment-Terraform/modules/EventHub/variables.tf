variable "location" {
  type        = string
  description = "Deployment region (ex. East US), for supported regions see https://docs.microsoft.com/en-us/azure/spring-apps/faq?pivots=programming-language-java#in-which-regions-is-azure-spring-apps-basicstandard-tier-available"
}

variable "name" {
  type        = string
  description = "Name of the Key Vault instance."
}

variable "network_rg_name" {
  type        = string
  description = "Name of the resource group containing network resources."
}

variable "pe_name" {
  type        = string
  description = "Name of the Private Endpoint associated with the key vault."
}

variable "reciever_mi_name" {
  type        = string
  description = "Name of the user-assigned Managed Identity that will be granted the Service Bus Owner role"
}

variable "rg_name" {
  type        = string
  description = "Name of the resource group to deploy the resource to."
}

variable "sender_mi_name" {
  type        = string
  description = "Name of the user-assigned Managed Identity that will be granted the Service Bus Owner role"
}

variable "sku" {
  type        = string
  description = "SKU of the Service Bus Namespace"
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "vnet_name" {
  type        = string
  description = "Name of the VNET."
}
