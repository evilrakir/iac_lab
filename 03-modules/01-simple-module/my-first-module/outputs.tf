# Module Output Values
# These expose data from the module to users

# ========================================================================
# APPLICATION OUTPUTS
# ========================================================================

output "app_identifier" {
  description = "Full application identifier"
  value       = local.app_identifier
}

output "app_name" {
  description = "Name of the application"
  value       = var.app_name
}

output "app_version" {
  description = "Version of the application"
  value       = var.app_version
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "port" {
  description = "Application port number"
  value       = var.port
}

# ========================================================================
# CONFIGURATION OUTPUTS
# ========================================================================

output "config_file_path" {
  description = "Path to the main configuration file"
  value       = local_file.app_config.filename
}

output "env_file_path" {
  description = "Path to the environment file"
  value       = local_file.env_config.filename
}

output "readme_file_path" {
  description = "Path to the README file (if created)"
  value       = var.create_readme ? local_file.readme[0].filename : null
}

output "all_file_paths" {
  description = "List of all created file paths"
  value = compact([
    local_file.app_config.filename,
    local_file.env_config.filename,
    var.create_readme ? local_file.readme[0].filename : ""
  ])
}

# ========================================================================
# FEATURE OUTPUTS
# ========================================================================

output "features" {
  description = "All feature flags"
  value       = var.features
}

output "enabled_features" {
  description = "List of enabled features"
  value       = local.enabled_features
}

output "feature_count" {
  description = "Number of enabled features"
  value       = length(local.enabled_features)
}

# ========================================================================
# DATABASE OUTPUTS
# ========================================================================

output "database_enabled" {
  description = "Whether database is enabled"
  value       = var.database_enabled
}

output "database_connection_string" {
  description = "Database connection string (if database is enabled)"
  value       = local.connection_string
  sensitive   = true  # Mark as sensitive to hide in output
}

output "database_config" {
  description = "Complete database configuration"
  value = var.database_enabled ? {
    enabled           = true
    type             = var.database_type
    host             = "${var.app_name}-db.${var.environment}.local"
    port             = 5432
    connection_string = local.connection_string
  } : {
    enabled = false
  }
}

# ========================================================================
# METADATA OUTPUTS
# ========================================================================

output "module_metadata" {
  description = "Information about this module"
  value = {
    version      = var.module_version
    files_created = local.config_count
    tags         = var.tags
  }
}

output "configuration_summary" {
  description = "Complete summary of the configuration"
  value = {
    application = {
      identifier = local.app_identifier
      name       = var.app_name
      version    = var.app_version
      environment = var.environment
      port       = var.port
    }
    
    features = {
      all     = var.features
      enabled = local.enabled_features
      count   = length(local.enabled_features)
    }
    
    database = {
      enabled = var.database_enabled
      type    = var.database_enabled ? var.database_type : null
    }
    
    files = {
      count = local.config_count
      paths = compact([
        local_file.app_config.filename,
        local_file.env_config.filename,
        var.create_readme ? local_file.readme[0].filename : ""
      ])
    }
    
    module = {
      version = var.module_version
      tags    = var.tags
    }
  }
}