variable "location" {
  type        = string
  description = "Deployment region (ex. East US), for supported regions see https://docs.microsoft.com/en-us/azure/spring-apps/faq?pivots=programming-language-java#in-which-regions-is-azure-spring-apps-basicstandard-tier-available"
}

variable "mi_name" {
  type        = string
  description = "Name of the user-assigned Managed Identity that will be granted the Key Vault Secrets User role."
}

variable "name" {
  type        = string
  description = "Name of the Key Vault instance."
}

variable "network_rg_name" {
  type        = string
  description = "Name of the resource group containing network resources."
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "tenant_id" {
  type        = string
  description = "ID of the target Azure tenant"
}

variable "vnet_name" {
  type        = string
  description = "Name of the VNET."
}

variable "workload_rg_name" {
  type        = string
  description = "Name of the resource group to deploy the resource to."
}
