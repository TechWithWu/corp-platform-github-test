terraform {
  required_version = ">= 1.9, < 2.0"

  # backend "azurerm" {
  #   use_oidc = true
  # }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.62"
    }

    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }

    modtm = {
      source  = "Azure/modtm"
      version = "~> 0.3"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}
