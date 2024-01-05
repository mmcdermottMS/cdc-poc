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
  network_rule_set {
    default_action = "Deny"
    public_network_access_enabled = false
    trusted_services_allowed = true

    dynamic "network_rules" {
      for_each = toset(var.subnets_allowed)

      content {
        subnet_id = network_rules.value
      }
    }
  }
}

resource "azurerm_role_assignment" "mi_sb_owner" {
  scope                = azurerm_servicebus_namespace.sb.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = module.owner_mi.principal_id
}

resource "azurerm_role_assignment" "mi_sb_sender" {
  scope                = azurerm_servicebus_namespace.sb.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = module.sender_mi.principal_id
}

module "pe" {
  source        = "../PrivateEndpoint"
  dnz_zone_id   = module.private_dns.id
  dns_zone_name = local.zone_name
  location      = var.location
  name          = var.pe_name
  resource_id   = azurerm_servicebus_namespace.sb.id
  resource_name = "namespace"
  rg_name       = var.network_rg_name
  subnet_id     = var.subnet_id
  tags          = var.tags
}
