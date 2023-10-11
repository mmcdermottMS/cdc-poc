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

variable "rg_name" {
  type        = string
  description = "Name of the resource group to deploy the resource to."
}

variable "sku" {
  type        = string
  description = "SKU of the container registry."
}

variable "tags" {
  type    = map(any)
  default = {}
}

