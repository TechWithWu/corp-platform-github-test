###############################################################################
# Terraform & Provider Requirements
###############################################################################

terraform {
  required_version = "~> 1.17"

  backend "azurerm" {
    use_oidc = true
  }

  required_providers {
    alz = {
      source  = "Azure/alz"
      version = "~> 0.22.1"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.35"
    }

    azapi = {
      source  = "azure/azapi"
      version = "~> 2.12"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}
