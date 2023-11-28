data "azurerm_client_config" "current" {}

locals {
  zone_name = "privatelink.vaultcore.azure.net"
}

module "private_dns" {
  source    = "../PrivateDNSZones"
  rg_name   = var.network_rg_name
  tags      = var.tags
  vnet_name = var.vnet_name
  zone_name = local.zone_name
}

module "mi" {
  source   = "../ManagedIdentity"
  location = var.location
  name     = var.mi_name
  rg_name  = var.rg_name
}

resource "azurerm_key_vault" "key_vault" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.rg_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.sku
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = var.tags
  network_acls {
    default_action = "Deny"
    bypass         = "None"
  }
}

resource "azurerm_role_assignment" "mi_secrets_reader" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.mi.principal_id
}

module "pe" {
  source        = "../PrivateEndpoint"
  dnz_zone_id   = module.private_dns.id
  dns_zone_name = local.zone_name
  location      = var.location
  name          = var.pe_name
  resource_id   = azurerm_key_vault.key_vault.id
  resource_name = "vault"
  rg_name       = var.network_rg_name
  subnet_id     = var.subnet_id
  tags          = var.tags
}
