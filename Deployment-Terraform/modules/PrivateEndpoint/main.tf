resource "azurerm_private_endpoint" "pe" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id
  tags                = var.tags
  private_service_connection {
    name                           = "${var.name}-private-link-connection"
    private_connection_resource_id = var.resource_id
    is_manual_connection           = false
    subresource_names              = [var.resource_name]
  }
  private_dns_zone_group {
    name                 = var.dns_zone_name
    private_dns_zone_ids = [var.dnz_zone_id]
  }
}
