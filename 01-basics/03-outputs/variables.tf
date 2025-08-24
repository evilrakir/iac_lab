# ╔════════════════════════════════════════════════════════════════════╗
# ║  VARIABLE DEFINITIONS - Inputs for Output Demonstration             ║
# ║  These variables are used to create resources we'll output          ║
# ╚════════════════════════════════════════════════════════════════════╝

# ========================================================================
# PROJECT CONFIGURATION
# ========================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "terraform-outputs-lab"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "domain" {
  description = "Base domain for the infrastructure"
  type        = string
  default     = "example.com"
}

# ========================================================================
# SERVER CONFIGURATION
# ========================================================================

variable "server_count" {
  description = "Number of servers to create"
  type        = number
  default     = 3
  
  validation {
    condition     = var.server_count >= 1 && var.server_count <= 10
    error_message = "Server count must be between 1 and 10."
  }
}

variable "server_roles" {
  description = "Roles to assign to servers"
  type        = list(string)
  default     = ["web", "app", "db", "cache", "queue"]
}

# ========================================================================
# TEAM CONFIGURATION
# ========================================================================

variable "team_members" {
  description = "List of team members"
  type        = list(string)
  default     = ["alice", "bob", "charlie", "diana"]
}

variable "team_lead" {
  description = "Name of the team lead"
  type        = string
  default     = "alice"
}

# ========================================================================
# ENVIRONMENT SETTINGS
# ========================================================================

variable "environments" {
  description = "List of environments to configure"
  type        = list(string)
  default     = ["development", "staging", "production"]
}

# ========================================================================
# FEATURE FLAGS
# ========================================================================

variable "enable_monitoring" {
  description = "Enable monitoring configuration"
  type        = bool
  default     = true
}

variable "enable_backups" {
  description = "Enable backup configuration"
  type        = bool
  default     = true
}

variable "enable_debug" {
  description = "Enable debug mode"
  type        = bool
  default     = false
}

# ========================================================================
# SENSITIVE VARIABLES
# ========================================================================

variable "api_key" {
  description = "API key for external services (sensitive)"
  type        = string
  default     = "demo-api-key-123456"
  sensitive   = true
}

variable "webhook_url" {
  description = "Webhook URL for notifications (sensitive)"
  type        = string
  default     = "https://hooks.example.com/webhook/abc123"
  sensitive   = true
}

# ========================================================================
# COMPLEX CONFIGURATION
# ========================================================================

variable "database_config" {
  description = "Database configuration object"
  type = object({
    engine  = string
    version = string
    size    = string
    backup  = bool
  })
  default = {
    engine  = "postgresql"
    version = "14.5"
    size    = "db.t3.micro"
    backup  = true
  }
}

variable "network_config" {
  description = "Network configuration"
  type = object({
    vpc_cidr     = string
    subnet_count = number
    enable_nat   = bool
  })
  default = {
    vpc_cidr     = "10.0.0.0/16"
    subnet_count = 3
    enable_nat   = true
  }
}

# ========================================================================
# TAGS AND METADATA
# ========================================================================

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Project     = "OutputsLab"
    CostCenter  = "Engineering"
    Owner       = "DevOps"
  }
}

variable "metadata" {
  description = "Additional metadata for resources"
  type = map(any)
  default = {
    version     = "1.0.0"
    deployed_by = "terraform-lab"
    purpose     = "learning"
  }
}