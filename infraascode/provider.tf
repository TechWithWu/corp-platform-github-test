###############################################################################
# Providers Configuration
###############################################################################

# In provider.tf
provider "azurerm" {
  features {}
  subscription_id = "7f493ff6-603b-4254-a6bf-e9acfc665866"
  use_oidc        = false
}

provider "azapi" {
  subscription_id = "7f493ff6-603b-4254-a6bf-e9acfc665866"
  use_oidc        = false
}
