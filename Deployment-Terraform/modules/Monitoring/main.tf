resource "azurerm_log_analytics_workspace" "law" {
  name                = var.law_name
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_application_insights" "ai" {
  name                = var.ai_name
  location            = var.location
  resource_group_name = var.rg_name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
  tags                = var.tags
}
