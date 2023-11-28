/**************************************************************/
/*                           GLOBAL                           */
/**************************************************************/
variable "vnet_addr_prefix" {
  type        = string
  description = "This is the address space of the virtual network, in CIDR notation"
}

variable "location" {
  type        = string
  description = "Deployment region (ex. East US), for supported regions see https://docs.microsoft.com/en-us/azure/spring-apps/faq?pivots=programming-language-java#in-which-regions-is-azure-spring-apps-basicstandard-tier-available"
  validation {
    condition     = contains(["eastus", "eastus2", "centralus", "westus", "westus2", "westus3"], var.location)
    error_message = "Valid regions are eastus, eastus2, centralus, westus, westus2, westus3"
  }
}

variable "name_prefix" {
  type        = string
  description = "This prefix will be used when naming resources. 42 characters max."
  validation {
    condition     = length(var.name_prefix) <= 42
    error_message = "name_prefix: 42 characters max allowed."
  }
}

variable "region_code" {
  type        = string
  description = "This is the short code representing the region and will be used in resource names."
}

variable "tags" {
  type    = map(any)
  default = {}
}

/**************************************************************/
/*                      RESOURCE NAMES                        */
/**************************************************************/
variable "acr_name" {
  type        = string
  description = "Name of the Azure Container Registry"
  default     = ""
}

variable "acr_mi_name" {
  type        = string
  description = "Name of the user-assigned Managed Identity that will be granted the ACR Pull role"
  default     = ""
}

variable "ai_name" {
  type        = string
  description = "The name of the Application Insights instance. If not specified, a name will be generated using the name_prefix and region_code variables."
  default     = ""
}

variable "kv_name" {
  type        = string
  description = "The name of the Key Vault instance. If not specified, a name will be generated using the name_prefix and region_code variables."
  default     = ""
}

variable "kv_mi_name" {
  type        = string
  description = "Name of the user-assigned Managed Identity that will be granted the Key Vault Secrets User role."
  default     = ""
}

variable "kv_sku" {
  type        = string
  description = "SKU of the Key Vault."
  default     = "standard"
}

variable "law_name" {
  type        = string
  description = "The name of the Log Analytics Workspace. If not specified, a name will be generated using the name_prefix and region_code variables."
  default     = ""
}

variable "network_rg_name" {
  type        = string
  description = "The name of the Resource Group containing the network resources. If not specified, a name will be generated using the name_prefix and region_code variables."
  default     = ""
}

variable "sb_name" {
  type        = string
  description = "Name of the Service Bus Namespace"
  default     = ""
}

variable "sb_owner_mi_name" {
  type        = string
  description = "Name of the user-assigned Managed Identity that will be granted the Service Bus Owner role"
  default     = ""
}

variable "sb_sender_mi_name" {
  type        = string
  description = "Name of the user-assigned Managed Identity that will be granted the Service Bus Sender role"
  default     = ""
}

variable "sb_sku" {
  type        = string
  description = "SKU of the Service Bus Namespace."
  default     = "Standard"
}

variable "vnet_name" {
  type        = string
  description = "The name of the VNET. If not specified, a name will be generated using the name_prefix and region_code variables."
  default     = ""
}

variable "workload_rg_name" {
  type        = string
  description = "The name of the Resource Group containing the PaaS resources. If not specified, a name will be generated using the name_prefix and region_code variables."
  default     = ""
}



