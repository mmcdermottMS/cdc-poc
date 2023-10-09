data "azurerm_client_config" "current" {}

locals {
  resource_prefix = var.resource_prefix
}

resource "random_string" "random" {
  length  = 4
  upper   = false
  special = false
}

/**************************************************************/
/*                            VNET                            */
/**************************************************************/
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = [var.vnet_addr_prefix]
  tags                = var.tags
}

/**************************************************************/
/*                           SUBNETS                          */
/**************************************************************/
resource "azurerm_subnet" "util_subnet" {
  name                 = "${local.resource_prefix}-subnet-util"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${cidrsubnet(var.vnet_addr_prefix, 8, 0)}"]
}

resource "azurerm_subnet" "pe_subnet" {
  name                 = "${local.resource_prefix}-subnet-pe"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${cidrsubnet(var.vnet_addr_prefix, 8, 1)}"]
}

resource "azurerm_subnet" "function_app_subnets" {
  name                 = "${local.resource_prefix}-subnet-${var.function_app_names[count.index]}"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${cidrsubnet(var.vnet_addr_prefix, 8, count.index + 2)}"]
  delegation {
    name = "${local.resource_prefix}-asp-delegation-${random_string.random.result}"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
  service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
  count             = length(var.function_app_names)
}

/**************************************************************/
/*                            NSGs                            */
/**************************************************************/
resource "azurerm_network_security_group" "util_nsg" {
  name                = "${local.resource_prefix}-nsg-util"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  security_rule {
    name                       = "allow-remote-vm-connections"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "deny-inbound-default"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "pe_nsg" {
  name                = "${local.resource_prefix}-nsg-pe"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  security_rule {
    name                       = "deny-inbound-default"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "functions_nsg" {
  name                = "${local.resource_prefix}-nsg-functions"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}

/**************************************************************/
/*                      NSG ASSOCIATIONS                      */
/**************************************************************/
resource "azurerm_subnet_network_security_group_association" "util_nsg_assoc" {
  subnet_id                 = azurerm_subnet.util_subnet.id
  network_security_group_id = azurerm_network_security_group.util_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "pe_nsg_assoc" {
  subnet_id                 = azurerm_subnet.pe_subnet.id
  network_security_group_id = azurerm_network_security_group.pe_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "function_app_nsg_assoc" {
  subnet_id                 = "/subscriptions/${data.azurerm_client_config.current.subscription_id}}/resourceGroups/${var.rg_name}/providers/Microsoft.Network/virtualNetworks/${var.vnet_name}/subnets/${local.resource_prefix}-subnet-${var.function_app_names[count.index]}"
  network_security_group_id = azurerm_network_security_group.functions_nsg.id
  count                     = length(var.function_app_names)
  depends_on = [
    azurerm_subnet.function_app_subnets
  ]
}
