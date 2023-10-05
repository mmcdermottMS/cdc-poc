data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = var.zone_name
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "${var.zone_name}-${var.vnet_name}-link"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}
