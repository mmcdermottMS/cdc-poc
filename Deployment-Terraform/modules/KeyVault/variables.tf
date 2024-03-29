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

variable "pe_name" {
  type        = string
  description = "Name of the Private Endpoint associated with the key vault."
}

variable "rg_name" {
  type        = string
  description = "Name of the resource group to deploy the resource to."
}

variable "sku" {
  type        = string
  description = "SKU of the Key Vault."
}

variable "subnets_allowed" {
  type = list(string)
  description = "List of Subnet IDs allowed to route to the resource"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet that will contain the Private Endpoint."
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "vnet_name" {
  type        = string
  description = "Name of the VNET."
}
