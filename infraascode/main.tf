resource "random_id" "id" {
  byte_length = 4
}

resource "azurerm_resource_group" "management" {
  location = var.location
  name     = var.management_resource_group
}

module "avm-ptn-alz-management" {
  source  = "Azure/avm-ptn-alz-management/azurerm"
  version = "~> 0.10.0"

  # Global / Resource Group Settings
  enable_telemetry                = var.enable_telemetry
  location                        = azurerm_resource_group.management.location
  resource_group_name             = azurerm_resource_group.management.name
  resource_group_creation_enabled = false

  automation_account_name                  = var.automation_account_name

  # Log Analytics Workspace Configuration (Cheapest / Pay-As-You-Go)
  log_analytics_workspace_name                            = var.log_analytics_workspace_name
  log_analytics_workspace_sku                             = var.log_analytics_workspace_sku
  log_analytics_workspace_retention_in_days               = 30
  log_analytics_workspace_daily_quota_gb                  = 1
  log_analytics_workspace_allow_resource_only_permissions = true
  log_analytics_workspace_cmk_for_query_forced            = true
  log_analytics_workspace_internet_ingestion_enabled      = true
  log_analytics_workspace_internet_query_enabled          = true

  # Data Collection Rules Configuration
  data_collection_rules = {
    change_tracking = {
      name     = "dcr-change-tracking-${random_id.id.hex}"
      location = azurerm_resource_group.management.location
    }
    vm_insights = {
      name     = "dcr-vm-insights-${random_id.id.hex}"
      location = azurerm_resource_group.management.location
    }
    defender_sql = {
      name     = "dcr-defender-sql-${random_id.id.hex}"
      location = azurerm_resource_group.management.location
    }
  }

  tags = local.tags
}