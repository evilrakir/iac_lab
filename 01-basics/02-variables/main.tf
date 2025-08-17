# Exercise 2: Variables - Input and Local Values
# Learn how to use variables, locals, and validation in Terraform

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

# Simple string variable
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "terraform-lab"
}

# Variable with validation
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

# Number variable with validation
variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 2
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

# Boolean variable
variable "enable_monitoring" {
  description = "Enable monitoring features"
  type        = bool
  default     = true
}

# List variable
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Map variable
variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    Owner       = "DevOps Team"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

# Object variable (complex type)
variable "database_config" {
  description = "Database configuration"
  type = object({
    engine   = string
    version  = string
    size     = string
    port     = number
    backup   = bool
  })
  default = {
    engine   = "postgres"
    version  = "14.5"
    size     = "db.t3.micro"
    port     = 5432
    backup   = true
  }
}

# Local values (computed from variables)
locals {
  # Construct resource prefix
  resource_prefix = "${var.project_name}-${var.environment}"
  
  # Determine instance type based on environment
  instance_type = var.environment == "production" ? "t3.large" : "t3.micro"
  
  # Merge tags with environment-specific tags
  complete_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      Timestamp   = timestamp()
    }
  )
  
  # Create a map of instances with names
  instances = {
    for i in range(var.instance_count) : 
    "instance-${i}" => {
      name = "${local.resource_prefix}-${i}"
      zone = element(var.availability_zones, i)
      monitoring = var.enable_monitoring
    }
  }
  
  # Conditional configuration
  backup_enabled = var.environment == "production" || var.database_config.backup
  
  # String manipulation
  sanitized_name = replace(lower(var.project_name), "/[^a-z0-9-]/", "-")
}

# Using variables and locals in resources
resource "local_file" "config" {
  filename = "${path.module}/output/config.json"
  content = jsonencode({
    project = {
      name        = var.project_name
      environment = var.environment
      prefix      = local.resource_prefix
    }
    instances = local.instances
    database  = var.database_config
    monitoring = {
      enabled = var.enable_monitoring
      backup  = local.backup_enabled
    }
    tags = local.complete_tags
  })
}

# Dynamic resource creation based on variables
resource "local_file" "instance_configs" {
  for_each = local.instances
  
  filename = "${path.module}/output/instances/${each.key}.yaml"
  content = yamlencode({
    name = each.value.name
    zone = each.value.zone
    type = local.instance_type
    monitoring = each.value.monitoring
    tags = local.complete_tags
  })
}

# Conditional resource creation
resource "local_file" "monitoring_config" {
  count = var.enable_monitoring ? 1 : 0
  
  filename = "${path.module}/output/monitoring.conf"
  content = <<-EOF
    # Monitoring Configuration
    Project: ${var.project_name}
    Environment: ${var.environment}
    Enabled: ${var.enable_monitoring}
    Backup: ${local.backup_enabled}
    
    # Instance Monitoring
    %{ for name, config in local.instances ~}
    ${name}: ${config.monitoring ? "enabled" : "disabled"}
    %{ endfor ~}
  EOF
}

# Using sensitive variables
variable "api_key" {
  description = "API key for external service"
  type        = string
  sensitive   = true
  default     = "secret-api-key"
}

resource "local_sensitive_file" "api_config" {
  filename = "${path.module}/output/.api_config"
  content = jsonencode({
    api_key = var.api_key
    project = var.project_name
  })
}

# Output examples
output "project_info" {
  description = "Project information"
  value = {
    name        = var.project_name
    environment = var.environment
    prefix      = local.resource_prefix
  }
}

output "instance_names" {
  description = "Names of all instances"
  value = [for inst in local.instances : inst.name]
}

output "database_endpoint" {
  description = "Database connection string"
  value = "${var.database_config.engine}://${local.resource_prefix}.example.com:${var.database_config.port}"
}

output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value = var.enable_monitoring
}