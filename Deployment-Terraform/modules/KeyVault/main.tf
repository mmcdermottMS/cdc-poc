module "private_dns" {
  source    = "../PrivateDNSZones"
  rg_name   = var.network_rg_name
  tags      = var.tags
  vnet_name = var.vnet_name
  zone_name = "privatelink.vaultcore.azure.net"
}

module "mi" {
  source   = "../ManagedIdentity"
  location = var.location
  name     = var.mi_name
  rg_name  = var.workload_rg_name
}

resource "azurerm_key_vault" "key_vault" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.workload_rg_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = var.tags
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = []
  }
}

#module "pe" {}
