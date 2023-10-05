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

resource "azurerm_subnet" "ehProducer_subnet" {
  name                 = "${local.resource_prefix}-subnet-ehProducer"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${cidrsubnet(var.vnet_addr_prefix, 8, 2)}"]
  delegation {
    name = "${local.resource_prefix}-asp-delegation-${random_string.random.result}"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
  service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

resource "azurerm_subnet" "ehConsumer_subnet" {
  name                 = "${local.resource_prefix}-subnet-ehConsumer"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${cidrsubnet(var.vnet_addr_prefix, 8, 3)}"]
  delegation {
    name = "${local.resource_prefix}-asp-delegation-${random_string.random.result}"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
  service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

resource "azurerm_subnet" "pyConsumer_subnet" {
  name                 = "${local.resource_prefix}-subnet-pyConsumer"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${cidrsubnet(var.vnet_addr_prefix, 8, 4)}"]
  delegation {
    name = "${local.resource_prefix}-asp-delegation-${random_string.random.result}"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
  service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

resource "azurerm_subnet" "sbConsumer_subnet" {
  name                 = "${local.resource_prefix}-subnet-sbConsumer"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${cidrsubnet(var.vnet_addr_prefix, 8, 5)}"]
  delegation {
    name = "${local.resource_prefix}-asp-delegation-${random_string.random.result}"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
  service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

resource "azurerm_subnet" "cosmosListener_subnet" {
  name                 = "${local.resource_prefix}-subnet-cosmosListener"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["${cidrsubnet(var.vnet_addr_prefix, 8, 6)}"]
  delegation {
    name = "${local.resource_prefix}-asp-delegation-${random_string.random.result}"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
  service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
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

resource "azurerm_subnet_network_security_group_association" "ehProducer_nsg_assoc" {
  subnet_id                 = azurerm_subnet.ehProducer_subnet.id
  network_security_group_id = azurerm_network_security_group.functions_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "ehConsumer_nsg_assoc" {
  subnet_id                 = azurerm_subnet.ehConsumer_subnet.id
  network_security_group_id = azurerm_network_security_group.functions_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "pyConsumer_nsg_assoc" {
  subnet_id                 = azurerm_subnet.pyConsumer_subnet.id
  network_security_group_id = azurerm_network_security_group.functions_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "sbConsumer_nsg_assoc" {
  subnet_id                 = azurerm_subnet.sbConsumer_subnet.id
  network_security_group_id = azurerm_network_security_group.functions_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "cosmosListener_nsg_assoc" {
  subnet_id                 = azurerm_subnet.cosmosListener_subnet.id
  network_security_group_id = azurerm_network_security_group.functions_nsg.id
}
