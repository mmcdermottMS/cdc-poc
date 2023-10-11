resource "azurerm_container_registry" "acr" {
  admin_enabled       = false
  location            = var.location
  name                = var.name
  resource_group_name = var.rg_name
  sku                 = var.sku
  tags                = var.tags
}

module "mi" {
  source   = "../ManagedIdentity"
  location = var.location
  name     = var.mi_name
  rg_name  = var.rg_name
}

