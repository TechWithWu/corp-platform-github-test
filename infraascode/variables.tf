
###############################################################################
# Input Variables
###############################################################################

variable "environment" {
  description = "Environment name (e.g. prod, nonprod)."
  type        = string
  default     = "nonprod"
}

variable "location" {
  description = <<DESC
Default Azure region used for ALZ-related artifacts, such as:
- Policy managed identities
- Deployment scripts
DESC
  type        = string
  default     = "centralus"
}

variable "enable_telemetry" {
  description = "Enable Azure Verified Module (AVM) telemetry via modtm."
  type        = bool
  default     = false
}

variable management_resource_group {
  type        = string
  default     = "rg-corp-plantform-management"
  description = "description"
}

variable log_analytics_workspace_name {
  type        = string
  default     = "corp-platform-log-analytics-workspace"
}

variable log_analytics_workspace_sku {
  type        = string
  default     = "PerGB2018"
}

variable automation_account_name {
  type        = string
  default     = "corp-automation"
}

