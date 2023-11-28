locals {
  zone_name = "privatelink.servicebus.windows.net"
}

module "private_dns" {
  source    = "../PrivateDNSZones"
  rg_name   = var.network_rg_name
  tags      = var.tags
  vnet_name = var.vnet_name
  zone_name = local.zone_name
}

module "owner_mi" {
  source   = "../ManagedIdentity"
  location = var.location
  name     = var.owner_mi_name
  rg_name  = var.rg_name
}

module "sender_mi" {
  source   = "../ManagedIdentity"
  location = var.location
  name     = var.sender_mi_name
  rg_name  = var.rg_name
}

resource "azurerm_servicebus_namespace" "sb" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = var.sku
  tags                = var.tags
  capacity            = var.sku == "Premium" ? 1 : 0
}
