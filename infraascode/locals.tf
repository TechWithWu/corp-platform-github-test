###############################################################################
# Locals
###############################################################################

locals {
  organization = "corp-platform"

  # Determine if target environment is production
  is_production = lower(var.environment) == "prod" || lower(var.environment) == "production"

  # Dynamic SKU evaluation:
  # - Non-production / dev: "Free" (cheapest tier)
  # - Production: "PerGB2018" (moderate / modern pay-as-you-go cost, avoiding high-commitment CapacityReservation)
  log_analytics_workspace_sku = local.is_production ? "PerGB2018" : (var.log_analytics_workspace_sku != null && var.log_analytics_workspace_sku != "" ? var.log_analytics_workspace_sku : "Free")

  tags = {
    Environment    = var.environment
    ManagementType = "alz"
    ManagedBy      = "terraform"
    Organization   = local.organization
  }
}