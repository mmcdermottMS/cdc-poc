data "azurerm_client_config" "current" {}

locals {
  resource_prefix  = "${var.name_prefix}-${var.region_code}"
  workload_rg_name = (var.workload_rg_name == "" ? "${local.resource_prefix}-workload-rg" : var.workload_rg_name)
  network_rg_name  = (var.network_rg_name == "" ? "${local.resource_prefix}-network-rg" : var.network_rg_name)
  law_name         = (var.law_name == "" ? "${local.resource_prefix}-law" : var.law_name)
  ai_name          = (var.ai_name == "" ? "${local.resource_prefix}-ai" : var.ai_name)
  vnet_name        = (var.vnet_name == "" ? "${local.resource_prefix}-vnet" : var.vnet_name)
  kv_name          = (var.kv_name == "" ? "${local.resource_prefix}-kv" : var.kv_name)
  kv_mi_name       = (var.kv_mi_name == "" ? "${local.resource_prefix}-mi-kvSecretsUser" : var.kv_mi_name)
  function_app_names = [
    "cosmosListener",
    "ehConsumer",
    "ehProducer",
    "sbConsumer",
    "pyConsumer"
  ]
}

resource "azurerm_resource_group" "workload_rg" {
  name     = local.workload_rg_name
  location = var.location
}

resource "azurerm_resource_group" "network_rg" {
  name     = local.network_rg_name
  location = var.location
}

module "monitoring" {
  source   = "./modules/Monitoring"
  law_name = local.law_name
  ai_name  = local.ai_name
  location = var.location
  rg_name  = azurerm_resource_group.workload_rg.name
  tags     = var.tags
}

module "networking" {
  source             = "./modules/Networking"
  function_app_names = local.function_app_names
  location           = var.location
  resource_prefix    = local.resource_prefix
  rg_name            = azurerm_resource_group.network_rg.name
  vnet_name          = local.vnet_name
  vnet_addr_prefix   = var.vnet_addr_prefix
  tags               = var.tags
}

module "keyvault" {
  source           = "./modules/KeyVault"
  location         = var.location
  mi_name          = local.kv_mi_name
  name             = local.kv_name
  network_rg_name  = azurerm_resource_group.network_rg.name
  tags             = var.tags
  tenant_id        = data.azurerm_client_config.current.tenant_id
  vnet_name        = module.networking.vnet_name
  workload_rg_name = azurerm_resource_group.workload_rg.name
  depends_on       = [module.networking]
}
