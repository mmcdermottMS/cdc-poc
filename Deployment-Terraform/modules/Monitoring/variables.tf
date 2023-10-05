variable "ai_name" {
  type        = string
  description = "Name of the log analytics workspace instance."
}

variable "location" {
  type        = string
  description = "Deployment region (ex. East US), for supported regions see https://docs.microsoft.com/en-us/azure/spring-apps/faq?pivots=programming-language-java#in-which-regions-is-azure-spring-apps-basicstandard-tier-available"
}

variable "law_name" {
  type        = string
  description = "Name of the log analytics workspace instance."
}

variable "rg_name" {
  type        = string
  description = "Name of the resource group to deploy the resource to."
}

variable "tags" {
  type    = map(any)
  default = {}
}
