###############################################################################
# Input Variables
###############################################################################

variable "environment" {
  description = "Target deployment environment (e.g., dev, test, prod)."
  type        = string
  default     = "nonprod"

  validation {
    condition     = contains(["dev", "development", "test", "stage", "staging", "nonprod", "prod", "production"], lower(var.environment))
    error_message = "The environment variable must be a recognized tier (e.g., dev, test, staging, nonprod, prod)."
  }
}

variable "location" {
  description = "Default Azure region for resources and ALZ management artifacts."
  type        = string
  default     = "centralus"
}

variable "enable_telemetry" {
  description = "Enable Azure Verified Module (AVM) telemetry via modtm."
  type        = bool
  default     = false
}

variable "management_resource_group" {
  description = "Name of the Azure Resource Group hosting management resources."
  type        = string
  default     = "rg-corp-platform-management"
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace."
  type        = string
  default     = "corp-platform-log-analytics-workspace"
}

variable "log_analytics_workspace_sku" {
  description = "The SKU for the Log Analytics Workspace. Defaults to 'Free' (cheapest) for non-prod. Production environments automatically resolve to 'PerGB2018' (moderate cost) unless explicitly overridden."
  type        = string
  default     = "Free"
}

variable "automation_account_name" {
  description = "Name of the Azure Automation account for management tasks."
  type        = string
  default     = "corp-automation"
}
