# ╔════════════════════════════════════════════════════════════════════╗
# ║  VARIABLE DEFINITIONS - Input Parameters for Terraform              ║
# ║  Best practice: Define all variables in variables.tf                ║
# ╚════════════════════════════════════════════════════════════════════╝

# This file is like your PowerShell param() block
# It defines all the inputs your Terraform configuration accepts

# ========================================================================
# BASIC VARIABLE TYPES
# ========================================================================

variable "project_name" {
  description = "Name of the project - used in resource naming"
  type        = string
  default     = "terraform-variables-lab"
}

variable "environment" {
  description = "Deployment environment (development, staging, production)"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "instance_count" {
  description = "Number of instances to create (1-10)"
  type        = number
  default     = 3
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "enable_monitoring" {
  description = "Enable monitoring and alerting features"
  type        = bool
  default     = true
}

# ========================================================================
# NETWORK CONFIGURATION
# ========================================================================

variable "port_number" {
  description = "Application port number (1024-65535)"
  type        = number
  default     = 8080
  
  validation {
    condition     = var.port_number >= 1024 && var.port_number <= 65535
    error_message = "Port must be between 1024 and 65535 (non-privileged ports)."
  }
}

variable "server_name" {
  description = "Server hostname (lowercase, alphanumeric with hyphens)"
  type        = string
  default     = "web-server-01"
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.server_name))
    error_message = "Server name must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "allowed_ips" {
  description = "Set of IP addresses allowed to access the service"
  type        = set(string)
  default     = ["10.0.0.1", "10.0.0.2", "10.0.0.3"]
}

# ========================================================================
# INFRASTRUCTURE CONFIGURATION
# ========================================================================

variable "availability_zones" {
  description = "List of availability zones for high availability"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "tags" {
  description = "Resource tags for organization and billing"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "TerraformLab"
    ManagedBy   = "Terraform"
    CostCenter  = "Engineering"
    Owner       = "DevOps Team"
  }
}

# ========================================================================
# COMPLEX CONFIGURATION OBJECTS
# ========================================================================

variable "database_config" {
  description = "Database configuration settings"
  type = object({
    engine   = string
    version  = string
    port     = number
    backup   = bool
    replicas = number
  })
  default = {
    engine   = "postgresql"
    version  = "14.5"
    port     = 5432
    backup   = true
    replicas = 2
  }
  
  validation {
    condition     = contains(["postgresql", "mysql", "mariadb"], var.database_config.engine)
    error_message = "Database engine must be postgresql, mysql, or mariadb."
  }
  
  validation {
    condition     = var.database_config.replicas >= 0 && var.database_config.replicas <= 5
    error_message = "Database replicas must be between 0 and 5."
  }
}

variable "server_configs" {
  description = "List of server configurations for different roles"
  type = list(object({
    name = string
    size = string
    role = string
  }))
  default = [
    {
      name = "web-1"
      size = "t2.micro"
      role = "webserver"
    },
    {
      name = "app-1"
      size = "t2.small"
      role = "application"
    },
    {
      name = "db-1"
      size = "t2.medium"
      role = "database"
    }
  ]
  
  validation {
    condition = alltrue([
      for server in var.server_configs : 
      contains(["webserver", "application", "database", "cache", "queue"], server.role)
    ])
    error_message = "Server role must be one of: webserver, application, database, cache, queue."
  }
}

# ========================================================================
# SENSITIVE VARIABLES
# ========================================================================

variable "api_key" {
  description = "API key for external service integration"
  type        = string
  sensitive   = true
  default     = "demo-api-key-12345"  # Never use real keys in defaults!
}

variable "database_password" {
  description = "Database password (should be provided at runtime)"
  type        = string
  sensitive   = true
  default     = "changeme"  # Never use real passwords in defaults!
}

# ========================================================================
# OPTIONAL VARIABLES
# ========================================================================

variable "custom_domain" {
  description = "Custom domain name (optional - leave null if not needed)"
  type        = string
  default     = null
}

variable "backup_retention_days" {
  description = "Number of days to retain backups (optional)"
  type        = number
  default     = null
  
  validation {
    condition     = var.backup_retention_days == null || (var.backup_retention_days >= 1 && var.backup_retention_days <= 365)
    error_message = "Backup retention days must be between 1 and 365 if specified."
  }
}

# ========================================================================
# FEATURE FLAGS
# ========================================================================

variable "enable_debug" {
  description = "Enable debug logging and verbose output"
  type        = bool
  default     = false
}

variable "enable_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "enable_ssl" {
  description = "Enable SSL/TLS encryption"
  type        = bool
  default     = true
}

# ========================================================================
# COMPUTED DEFAULTS (Using Locals in main.tf)
# ========================================================================
# Note: You cannot reference other variables in default values
# Use locals in main.tf for computed values like:
# - resource_prefix = "${var.project_name}-${var.environment}"
# - instance_type = var.environment == "production" ? "t2.large" : "t2.micro"