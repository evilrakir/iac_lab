# Module Outputs - Data the module exposes to callers
# Like return values from a PowerShell function

output "app_summary" {
  description = "Summary of the deployed application configuration"
  value = {
    name        = var.app_name
    environment = var.environment
    replicas    = var.replicas
    logging     = var.enable_logging
    has_db      = var.database_config != null
    tags        = var.tags
  }
}

output "config_file_path" {
  description = "Path to the generated config file"
  value       = local_file.app_config.filename
}
