output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "pe_subnet_id" {
  value = azurerm_subnet.pe_subnet.id
}
