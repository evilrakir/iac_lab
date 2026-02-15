# Module Input Variables
# These define what values the module accepts from users

# ========================================================================
# REQUIRED VARIABLES (no defaults)
# ========================================================================

variable "app_name" {
  description = "Name of the application"
  type        = string
  # No default - users MUST provide this
  
  validation {
    condition     = length(var.app_name) > 0 && length(var.app_name) <= 50
    error_message = "App name must be between 1 and 50 characters."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  # No default - users MUST provide this
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# ========================================================================
# OPTIONAL VARIABLES (with defaults)
# ========================================================================

variable "app_version" {
  description = "Version of the application"
  type        = string
  default     = "1.0.0"
  
  validation {
    # Simple semantic versioning check
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.app_version))
    error_message = "App version must follow semantic versioning (e.g., 1.0.0)."
  }
}

variable "port" {
  description = "Port number for the application"
  type        = number
  default     = 8080
  
  validation {
    condition     = var.port >= 1024 && var.port <= 65535
    error_message = "Port must be between 1024 and 65535."
  }
}

variable "features" {
  description = "Feature flags for the application"
  type        = map(bool)
  default = {
    monitoring = true
    logging    = true
    caching    = false
    debug      = false
  }
}

variable "database_enabled" {
  description = "Whether to enable database configuration"
  type        = bool
  default     = false
}

variable "database_type" {
  description = "Type of database (postgresql, mysql, sqlite)"
  type        = string
  default     = "postgresql"
  
  validation {
    condition     = contains(["postgresql", "mysql", "sqlite"], var.database_type)
    error_message = "Database type must be postgresql, mysql, or sqlite."
  }
}

variable "create_readme" {
  description = "Whether to create a README file"
  type        = bool
  default     = true
}

variable "output_path" {
  description = "Path where files should be created (empty for module default)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    module     = "simple-app-config"
  }
}

# ========================================================================
# MODULE METADATA (internal use)
# ========================================================================

variable "module_version" {
  description = "Version of this module"
  type        = string
  default     = "1.0.0"
  
  # This is typically hardcoded in the module
  # Users shouldn't override this
}