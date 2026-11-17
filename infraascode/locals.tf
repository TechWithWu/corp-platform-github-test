
###############################################################################
# Locals
###############################################################################

locals {
  organization = "corp-platform"

  # Single source of truth for ALZ artifact region.
  # (Previously `var.location` was defined but hardcoded to "centralus".)
  alz_location = var.location

  tags = {
    Environment    = var.environment
    ManagementType = "alz"
    ManagedBy      = "terraform"
    Organization   = local.organization
  }
}