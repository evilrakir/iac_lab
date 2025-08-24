# ╔════════════════════════════════════════════════════════════════════╗
# ║  OUTPUT VALUES - Making Data Available                              ║
# ║  Learn how to expose values from your Terraform configuration       ║
# ╚════════════════════════════════════════════════════════════════════╝

# Outputs are like PowerShell Write-Output or return values
# They make data available for:
# 1. Display after terraform apply
# 2. Querying with terraform output command
# 3. Sharing between Terraform configurations

# ========================================================================
# BASIC OUTPUTS
# ========================================================================

output "project_info" {
  description = "Basic project information"
  value = {
    name        = var.project_name
    environment = var.environment
    prefix      = local.resource_prefix
  }
}

output "instance_count" {
  description = "Number of instances created"
  value       = var.instance_count
}

# ========================================================================
# COMPUTED OUTPUTS
# ========================================================================

output "resource_summary" {
  description = "Summary of all created resources"
  value = {
    total_files    = var.instance_count + length(var.server_configs) + (var.enable_monitoring ? 2 : 1)
    instance_files = var.instance_count
    server_files   = length(var.server_configs)
    monitoring     = var.enable_monitoring ? "enabled" : "disabled"
  }
}

output "primary_zone" {
  description = "Primary availability zone"
  value       = local.primary_zone
}

# ========================================================================
# CONDITIONAL OUTPUTS
# ========================================================================

output "monitoring_status" {
  description = "Monitoring configuration status"
  value = var.enable_monitoring ? "Monitoring is enabled at ./terraform-lab-output/monitoring.conf" : "Monitoring is disabled"
}

output "custom_domain_info" {
  description = "Custom domain configuration"
  value = var.custom_domain != null ? "Custom domain: ${var.custom_domain}" : "No custom domain configured"
}

# ========================================================================
# SENSITIVE OUTPUTS
# ========================================================================

output "api_key_hint" {
  description = "API key information (redacted)"
  value       = "API key is configured (hidden due to sensitive flag)"
  sensitive   = false  # We don't output the actual key
}

# ========================================================================
# COMPLEX OUTPUTS
# ========================================================================

output "server_mapping" {
  description = "Mapping of server names to configurations"
  value = {
    for server in var.server_configs : 
    server.name => {
      role = server.role
      size = server.size
      file = "./terraform-lab-output/servers/${server.name}.conf"
    }
  }
}

output "zone_distribution" {
  description = "How instances are distributed across zones"
  value = [
    for i in range(var.instance_count) : {
      instance = "instance-${i}"
      zone     = var.availability_zones[i % length(var.availability_zones)]
    }
  ]
}

# ========================================================================
# FORMATTED OUTPUTS
# ========================================================================

output "configuration_files" {
  description = "List of all created configuration files"
  value = concat(
    ["./terraform-lab-output/variable-values.txt"],
    ["./terraform-lab-output/terraform-vs-powershell-variables.ps1"],
    [for i in range(var.instance_count) : "./terraform-lab-output/instances/instance-${i}.yaml"],
    [for server in var.server_configs : "./terraform-lab-output/servers/${server.name}.conf"],
    var.enable_monitoring ? ["./terraform-lab-output/monitoring.conf"] : []
  )
}

# ========================================================================
# USER-FRIENDLY MESSAGE OUTPUT
# ========================================================================

output "lab_complete_message" {
  description = "Completion message for the lab"
  value = <<-EOT
    
    ✅ Terraform Variables Lab Complete!
    
    Created ${var.instance_count + length(var.server_configs) + (var.enable_monitoring ? 2 : 1)} files demonstrating:
    - All variable types (string, number, bool, list, map, object)
    - Variable validation
    - Local values
    - Conditional resources
    - For loops and count
    
    Check the ./terraform-lab-output/ directory to see all created files.
    
    Next steps:
    1. Try changing variables in terraform.tfvars
    2. Override variables with: terraform apply -var="environment=production"
    3. Explore the generated PowerShell comparison script
  EOT
}