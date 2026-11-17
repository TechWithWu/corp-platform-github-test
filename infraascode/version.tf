###############################################################################
# Terraform & Provider Requirements
###############################################################################

terraform {
  required_version = ">= 1.9, < 2.0"

  backend "azurerm" {
    use_oidc = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.35"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
