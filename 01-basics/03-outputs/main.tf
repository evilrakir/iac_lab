# Exercise 3: Outputs - Displaying Results and Data
# Learn how to use outputs to expose information from your Terraform configuration

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

# Variables for our demonstration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "outputs-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "team_members" {
  description = "List of team members"
  type        = list(string)
  default     = ["alice", "bob", "charlie"]
}

variable "enable_monitoring" {
  description = "Enable monitoring features"
  type        = bool
  default     = true
}

# Local values for computed data
locals {
  # Timestamp for when resources were created
  creation_time = timestamp()
  
  # Construct full project identifier
  project_id = "${var.project_name}-${var.environment}"
  
  # Create resource tags
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = local.creation_time
  }
  
  # Process team data
  team_data = {
    for member in var.team_members : member => {
      username = lower(member)
      email    = "${lower(member)}@company.com"
      role     = member == "alice" ? "lead" : "developer"
    }
  }
}

# Create some resources to demonstrate outputs
resource "local_file" "project_info" {
  filename = "${path.module}/output/${local.project_id}-info.json"
  content = jsonencode({
    project     = var.project_name
    environment = var.environment
    created_at  = local.creation_time
    team        = local.team_data
    tags        = local.common_tags
  })
}

resource "local_file" "team_directory" {
  filename = "${path.module}/output/team-directory.yaml"
  content = yamlencode({
    team = {
      name    = "${var.project_name} Team"
      members = local.team_data
      total   = length(var.team_members)
    }
  })
}

# Conditional resource based on monitoring flag
resource "local_file" "monitoring_config" {
  count = var.enable_monitoring ? 1 : 0
  
  filename = "${path.module}/output/monitoring.conf"
  content = <<-EOF
    # Monitoring Configuration for ${var.project_name}
    project=${var.project_name}
    environment=${var.environment}
    enabled=${var.enable_monitoring}
    team_size=${length(var.team_members)}
    created=${local.creation_time}
  EOF
}

# OUTPUTS SECTION - This is what this exercise focuses on!

# 1. Simple string output
output "project_name" {
  description = "The name of the project"
  value       = var.project_name
}

# 2. Computed string output
output "project_identifier" {
  description = "Full project identifier with environment"
  value       = local.project_id
}

# 3. Number output
output "team_size" {
  description = "Number of team members"
  value       = length(var.team_members)
}

# 4. Boolean output
output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.enable_monitoring
}

# 5. List output
output "team_members" {
  description = "List of all team members"
  value       = var.team_members
}

# 6. Map/Object output
output "team_details" {
  description = "Detailed information about team members"
  value       = local.team_data
}

# 7. Resource attribute output
output "project_info_file" {
  description = "Path to the created project info file"
  value       = local_file.project_info.filename
}

# 8. Conditional output (only shows if monitoring is enabled)
output "monitoring_config_file" {
  description = "Path to monitoring config file (if created)"
  value       = var.enable_monitoring ? local_file.monitoring_config[0].filename : "monitoring disabled"
}

# 9. Complex computed output
output "environment_summary" {
  description = "Complete environment summary"
  value = {
    project = {
      name        = var.project_name
      id          = local.project_id
      environment = var.environment
    }
    team = {
      count   = length(var.team_members)
      members = var.team_members
      lead    = [for name, data in local.team_data : name if data.role == "lead"][0]
    }
    resources = {
      files_created = length([
        local_file.project_info.filename,
        local_file.team_directory.filename
      ]) + (var.enable_monitoring ? 1 : 0)
      monitoring_enabled = var.enable_monitoring
    }
    metadata = {
      created_at = local.creation_time
      tags       = local.common_tags
    }
  }
}

# 10. Sensitive output (marked as sensitive)
output "team_emails" {
  description = "Email addresses of team members"
  value       = [for member, data in local.team_data : data.email]
  sensitive   = true  # This will hide the output in terraform apply
}

# 11. Output with formatting
output "deployment_summary" {
  description = "Formatted deployment summary"
  value = <<-EOT
    =====================================
    TERRAFORM DEPLOYMENT SUMMARY
    =====================================
    Project: ${var.project_name}
    Environment: ${upper(var.environment)}
    Team Size: ${length(var.team_members)}
    Project ID: ${local.project_id}
    
    Files Created:
    - ${local_file.project_info.filename}
    - ${local_file.team_directory.filename}
    ${var.enable_monitoring ? "- ${local_file.monitoring_config[0].filename}" : "- (monitoring disabled)"}
    
    Deployed at: ${local.creation_time}
    =====================================
  EOT
}

# 12. Output for use by other Terraform configurations
output "for_other_configs" {
  description = "Data to be consumed by other Terraform configurations"
  value = {
    # These would typically be used as data sources in other configs
    project_id    = local.project_id
    environment   = var.environment
    resource_tags = local.common_tags
    
    # File paths that other configs might reference
    files = {
      project_info    = local_file.project_info.filename
      team_directory  = local_file.team_directory.filename
      monitoring_conf = var.enable_monitoring ? local_file.monitoring_config[0].filename : null
    }
    
    # Computed values others might need
    team_count = length(var.team_members)
    is_production = var.environment == "production"
  }
}