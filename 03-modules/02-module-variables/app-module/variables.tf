# Module Variables - All Terraform Variable Types Demonstrated
# ============================================================
# These are the "parameters" of our module.
# Each one shows a different variable type.

# STRING (Required - no default) = [Parameter(Mandatory)][string]
variable "app_name" {
  description = "Name of the application"
  type        = string
  validation {
    condition     = length(var.app_name) >= 2 && length(var.app_name) <= 50
    error_message = "App name must be between 2 and 50 characters."
  }
}

# STRING (with default + validation) = [ValidateSet()][string]
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

# NUMBER = [int]
variable "replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 1
  validation {
    condition     = var.replicas >= 1 && var.replicas <= 10
    error_message = "Replicas must be between 1 and 10."
  }
}

# BOOL = [bool] or [switch]
variable "enable_logging" {
  description = "Whether to enable application logging"
  type        = bool
  default     = false
}

# LIST(STRING) = [string[]]
variable "allowed_origins" {
  description = "List of allowed CORS origins"
  type        = list(string)
  default     = []
}

# MAP(STRING) = [hashtable]
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# OBJECT = [PSCustomObject]
variable "database_config" {
  description = "Database configuration (null = no database)"
  type = object({
    engine         = string
    version        = string
    storage_gb     = number
    backup_enabled = bool
  })
  default = null
}

# TUPLE = Fixed-length typed list (no direct PS equivalent)
variable "port_range" {
  description = "Start and end port [min, max]"
  type        = tuple([number, number])
  default     = [8080, 8080]
}
