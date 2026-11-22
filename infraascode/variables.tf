###############################################################################
# Input Variables - Connectivity Hub
###############################################################################

variable "environment" {
  description = "Target deployment environment (e.g., dev, test, stage, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "development", "test", "stage", "staging", "nonprod", "prod", "production", "demo"], lower(var.environment))
    error_message = "The environment variable must be a recognized tier (e.g., dev, test, staging, prod, demo)."
  }
}

variable "location" {
  description = "Azure region where the Connectivity Hub resources will be provisioned."
  type        = string
  default     = "centralus"
}

variable "enable_telemetry" {
  description = "Enable Azure Verified Module (AVM) telemetry via modtm."
  type        = bool
  default     = false
}

variable "hub_vnet_name" {
  description = "Name of the centralized Hub Virtual Network."
  type        = string
  default     = "vnet-platform-connectivity"
}

variable "hub_vnet_cidr" {
  description = "Address space for the centralized Hub Virtual Network in CIDR notation."
  type        = string
  default     = "10.0.0.0/16"
}

variable "hub_shared_subnet_cidr" {
  description = "Address prefix for the Hub shared services/management subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "resource_group_name" {
  description = "Custom name for the Hub resource group. If omitted, a standard name with random suffix will be generated."
  type        = string
  default     = ""
}

variable "custom_tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
