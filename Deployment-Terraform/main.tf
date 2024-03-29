data "azurerm_subscription" "current" {
}

locals {
  ai_name           = (var.ai_name == "" ? "${local.resource_prefix}-ai" : var.ai_name)
  acr_mi_name       = (var.acr_mi_name == "" ? "${local.resource_prefix}-mi-acrPull" : var.acr_mi_name)
  acr_name          = (var.acr_name == "" ? replace("${local.resource_prefix}-acr", "-", "") : var.acr_name) //substr may be needed here
  kv_mi_name        = (var.kv_mi_name == "" ? "${local.resource_prefix}-mi-kvSecretsUser" : var.kv_mi_name)
  kv_name           = (var.kv_name == "" ? "${local.resource_prefix}-kv" : var.kv_name)
  law_name          = (var.law_name == "" ? "${local.resource_prefix}-law" : var.law_name)
  network_rg_name   = (var.network_rg_name == "" ? "${local.resource_prefix}-network-rg" : var.network_rg_name)
  resource_prefix   = "${var.name_prefix}-${var.region_code}"
  sb_owner_mi_name  = (var.sb_owner_mi_name == "" ? "${local.resource_prefix}-mi-sbnsOwner" : var.sb_owner_mi_name)
  sb_sender_mi_name = (var.sb_sender_mi_name == "" ? "${local.resource_prefix}-mi-sbnsSender" : var.sb_sender_mi_name)
  sb_name           = (var.sb_name == "" ? "${local.resource_prefix}-sbns" : var.sb_name) //substr may be needed here
  subscription_id   = data.azurerm_subscription.current.id
  vnet_name         = (var.vnet_name == "" ? "${local.resource_prefix}-vnet" : var.vnet_name)
  workload_rg_name  = (var.workload_rg_name == "" ? "${local.resource_prefix}-workload-rg" : var.workload_rg_name)

  //https://stackoverflow.com/questions/58594506/how-to-for-each-through-a-listobjects-in-terraform-0-12
  //https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9
  function_app_names = [
    "cosmosListener",
    "ehConsumer",
    "ehProducer",
    "sbConsumer",
    "pyConsumer"
  ]

  function_app_subnets = [
    "${data.azurerm_subscription.current.id}/resourceGroups/${local.network_rg_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}/subnets/${local.resource_prefix}-subnet-cosmosListener",
    "${data.azurerm_subscription.current.id}/resourceGroups/${local.network_rg_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}/subnets/${local.resource_prefix}-subnet-ehConsumer",
    "${data.azurerm_subscription.current.id}/resourceGroups/${local.network_rg_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}/subnets/${local.resource_prefix}-subnet-ehProducer",
    "${data.azurerm_subscription.current.id}/resourceGroups/${local.network_rg_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}/subnets/${local.resource_prefix}-subnet-sbConsumer",
    "${data.azurerm_subscription.current.id}/resourceGroups/${local.network_rg_name}/providers/Microsoft.Network/virtualNetworks/${local.vnet_name}/subnets/${local.resource_prefix}-subnet-pyConsumer"
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

module "monitoring" {
  source   = "./modules/Monitoring"
  law_name = local.law_name
  ai_name  = local.ai_name
  location = var.location
  rg_name  = azurerm_resource_group.workload_rg.name
  tags     = var.tags
}

module "keyvault" {
  source          = "./modules/KeyVault"
  location        = var.location
  mi_name         = local.kv_mi_name
  name            = local.kv_name
  network_rg_name = azurerm_resource_group.network_rg.name
  pe_name         = "${local.resource_prefix}-pe-kv"
  rg_name         = azurerm_resource_group.workload_rg.name
  sku             = var.kv_sku
  subnets_allowed = local.function_app_subnets
  subnet_id       = module.networking.pe_subnet_id
  tags            = var.tags
  vnet_name       = module.networking.vnet_name
  depends_on      = [module.networking]
}

module "acr" {
  source   = "./modules/ContainerRegistry"
  location = var.location
  mi_name  = local.acr_mi_name
  name     = local.acr_name
  rg_name  = azurerm_resource_group.workload_rg.name
  sku      = "Standard"
  tags     = var.tags
}

module "sb" {
  source          = "./modules/ServiceBus"
  location        = var.location
  name            = local.sb_name
  owner_mi_name   = local.sb_owner_mi_name
  sender_mi_name  = local.sb_sender_mi_name
  sku             = var.sb_sku
  subnets_allowed = local.function_app_subnets
  subnet_id       = module.networking.pe_subnet_id
  network_rg_name = azurerm_resource_group.network_rg.name
  pe_name         = "${local.resource_prefix}-pe-sb"
  rg_name         = azurerm_resource_group.workload_rg.name
  vnet_name       = module.networking.vnet_name
  tags            = var.tags
  depends_on      = [module.networking]
}
