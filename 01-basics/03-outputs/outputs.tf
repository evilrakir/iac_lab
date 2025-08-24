# ╔════════════════════════════════════════════════════════════════════╗
# ║  OUTPUT VALUES - Exposing Terraform Data                            ║
# ║  Learn all output patterns and best practices                       ║
# ╚════════════════════════════════════════════════════════════════════╝

# Outputs are like PowerShell Write-Output or return values
# They serve three main purposes:
# 1. Display values after terraform apply
# 2. Share data between Terraform configurations
# 3. Query values with terraform output command

# ========================================================================
# SECTION 1: BASIC OUTPUT TYPES
# ========================================================================

# String output
output "project_name" {
  description = "The name of the project"
  value       = var.project_name
}

# Number output
output "server_count" {
  description = "Number of servers created"
  value       = var.server_count
}

# Boolean output
output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.enable_monitoring
}

# List output
output "team_members" {
  description = "List of team members"
  value       = var.team_members
}

# Map output
output "tags" {
  description = "Resource tags"
  value       = var.tags
}

# ========================================================================
# SECTION 2: RESOURCE ATTRIBUTE OUTPUTS
# ========================================================================

# Output from a resource
output "server_id" {
  description = "Generated server ID"
  value       = random_id.server_id.hex
}

output "server_name" {
  description = "Generated server name"
  value       = random_pet.server_name.id
}

output "server_port" {
  description = "Generated server port"
  value       = random_integer.port.result
}

# Output resource metadata
output "app_config_file" {
  description = "Path to the application configuration file"
  value       = local_file.app_config.filename
}

output "app_config_id" {
  description = "Terraform resource ID for app config"
  value       = local_file.app_config.id
}

# ========================================================================
# SECTION 3: SENSITIVE OUTPUTS
# ========================================================================

# Sensitive string output (hidden in CLI output)
output "database_password" {
  description = "Generated database password (sensitive)"
  value       = random_password.db_password.result
  sensitive   = true
  # In PowerShell: like [SecureString]
}

output "api_key" {
  description = "API key for external services"
  value       = var.api_key
  sensitive   = true
}

# Non-sensitive output about sensitive data
output "database_password_info" {
  description = "Information about the database password"
  value = {
    length  = length(random_password.db_password.result)
    special = random_password.db_password.special
    numeric = random_password.db_password.numeric
  }
  # Provides info without exposing the actual password
}

# ========================================================================
# SECTION 4: COMPUTED OUTPUTS
# ========================================================================

# Output using locals
output "project_id" {
  description = "Complete project identifier"
  value       = local.project_id
}

# Output with string interpolation
output "connection_string" {
  description = "Database connection string (without password)"
  value       = "postgresql://admin@${var.environment}-db.${var.domain}:5432/${var.project_name}"
}

# Output with conditional
output "environment_type" {
  description = "Environment classification"
  value       = var.environment == "production" ? "PRODUCTION" : "NON-PRODUCTION"
}

# ========================================================================
# SECTION 5: COLLECTION OUTPUTS
# ========================================================================

# Output list of server configurations
output "server_list" {
  description = "List of all servers created"
  value       = local.servers
}

# Output specific server by index
output "primary_server" {
  description = "Primary server configuration"
  value       = local.servers[0]
}

# Output map of environment configurations
output "environment_configs" {
  description = "Configuration for each environment"
  value       = local.env_configs
}

# Output filtered list
output "production_configs" {
  description = "Only production environment configurations"
  value = {
    for env, config in local.env_configs : 
    env => config if config.is_production
  }
}

# ========================================================================
# SECTION 6: CONDITIONAL OUTPUTS
# ========================================================================

# Output only if monitoring is enabled
output "monitoring_config_path" {
  description = "Path to monitoring configuration (if enabled)"
  value       = var.enable_monitoring ? local_file.monitoring_config[0].filename : null
}

# Output with conditional message
output "monitoring_status" {
  description = "Monitoring configuration status"
  value = var.enable_monitoring ? 
    "Monitoring is ENABLED at ${local_file.monitoring_config[0].filename}" : 
    "Monitoring is DISABLED"
}

# Complex conditional output
output "backup_configuration" {
  description = "Backup configuration details"
  value = var.enable_backups ? {
    enabled   = true
    frequency = var.environment == "production" ? "hourly" : "daily"
    retention = var.environment == "production" ? "30 days" : "7 days"
    location  = "s3://backups.${var.domain}/${var.project_name}"
  } : {
    enabled = false
    reason  = "Backups disabled by configuration"
  }
}

# ========================================================================
# SECTION 7: COMPLEX STRUCTURED OUTPUTS
# ========================================================================

# Complete infrastructure summary
output "infrastructure_summary" {
  description = "Complete infrastructure details"
  value = {
    project = {
      name        = var.project_name
      id          = local.project_id
      environment = var.environment
      domain      = var.domain
    }
    
    servers = {
      count   = var.server_count
      base_id = random_id.server_id.hex
      name    = random_pet.server_name.id
      port    = random_integer.port.result
      list    = local.servers
    }
    
    team = {
      size    = length(var.team_members)
      members = var.team_members
      lead    = var.team_lead
    }
    
    features = {
      monitoring = var.enable_monitoring
      backups    = var.enable_backups
      debug      = var.enable_debug
    }
    
    files = {
      total = local.total_files_created
      paths = {
        app_config   = local_file.app_config.filename
        summary      = local_file.infrastructure_summary.filename
        monitoring   = var.enable_monitoring ? local_file.monitoring_config[0].filename : null
      }
    }
    
    metadata = merge(var.metadata, {
      created_at = timestamp()
      terraform_version = "1.0+"
    })
  }
}

# ========================================================================
# SECTION 8: FORMATTED OUTPUTS
# ========================================================================

# Multi-line formatted output
output "deployment_report" {
  description = "Human-readable deployment report"
  value = <<-EOT
    
    ╔════════════════════════════════════════════════════════════════════╗
    ║                    TERRAFORM DEPLOYMENT REPORT                      ║
    ╚════════════════════════════════════════════════════════════════════╝
    
    PROJECT INFORMATION
    ├─ Name: ${var.project_name}
    ├─ ID: ${local.project_id}
    ├─ Environment: ${upper(var.environment)}
    └─ Domain: ${var.domain}
    
    SERVER CONFIGURATION
    ├─ Count: ${var.server_count}
    ├─ Base Name: ${random_pet.server_name.id}
    ├─ Server ID: ${random_id.server_id.hex}
    └─ Base Port: ${random_integer.port.result}
    
    TEAM
    ├─ Size: ${length(var.team_members)}
    ├─ Lead: ${var.team_lead}
    └─ Members: ${join(", ", var.team_members)}
    
    FEATURES
    ├─ Monitoring: ${var.enable_monitoring ? "✓ Enabled" : "✗ Disabled"}
    ├─ Backups: ${var.enable_backups ? "✓ Enabled" : "✗ Disabled"}
    └─ Debug: ${var.enable_debug ? "✓ Enabled" : "✗ Disabled"}
    
    FILES CREATED
    ├─ Total: ${local.total_files_created}
    ├─ App Config: ${local_file.app_config.filename}
    ├─ Servers: ${var.server_count} configuration files
    └─ Environments: ${length(var.environments)} configuration files
    
    ════════════════════════════════════════════════════════════════════
    Deployment completed at: ${timestamp()}
    ════════════════════════════════════════════════════════════════════
  EOT
}

# ========================================================================
# SECTION 9: OUTPUTS FOR TERRAFORM CONSUMERS
# ========================================================================

# Output for use by other Terraform configurations
output "for_remote_state" {
  description = "Values to be consumed via remote state"
  value = {
    # Network information
    network = {
      vpc_cidr     = var.network_config.vpc_cidr
      subnet_count = var.network_config.subnet_count
    }
    
    # Database connection info (without sensitive data)
    database = {
      engine   = var.database_config.engine
      version  = var.database_config.version
      endpoint = "${var.environment}-db.${var.domain}"
      port     = 5432
    }
    
    # Server endpoints
    endpoints = {
      for server in local.servers : 
      server.name => server.url
    }
    
    # Resource identifiers
    identifiers = {
      project_id = local.project_id
      server_id  = random_id.server_id.hex
      tags       = local.common_tags
    }
  }
}

# ========================================================================
# SECTION 10: COMMAND-LINE USAGE EXAMPLES
# ========================================================================

output "cli_usage_examples" {
  description = "Examples of using terraform output command"
  value = <<-EOT
    
    TERRAFORM OUTPUT COMMAND EXAMPLES:
    ===================================
    
    # Get all outputs
    terraform output
    
    # Get specific output
    terraform output server_name
    
    # Get output in JSON format
    terraform output -json
    
    # Get specific output as JSON
    terraform output -json server_list
    
    # Get raw output (no quotes for strings)
    terraform output -raw project_name
    
    # Use in scripts (PowerShell)
    $serverName = terraform output -raw server_name
    
    # Use in scripts (Bash)
    SERVER_NAME=$(terraform output -raw server_name)
    
    # Get sensitive output (must use -json)
    terraform output -json database_password
    
    TIP: Outputs are stored in terraform.tfstate and can be 
    queried anytime after terraform apply!
  EOT
}