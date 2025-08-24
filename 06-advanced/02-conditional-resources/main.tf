# Exercise: Advanced Conditional Resources
# Master complex conditional logic and dynamic resource creation

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  required_version = ">= 1.0"
}

# ========================================================================
# SECTION 1: CONDITIONAL VARIABLES
# ========================================================================

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "enable_monitoring" {
  description = "Enable monitoring resources"
  type        = bool
  default     = true
}

variable "enable_backups" {
  description = "Enable backup resources"
  type        = bool
  default     = true
}

variable "enable_high_availability" {
  description = "Enable HA configuration"
  type        = bool
  default     = false
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

variable "features" {
  description = "Feature flags"
  type = map(bool)
  default = {
    logging      = true
    metrics      = true
    alerting     = false
    auto_scaling = false
    encryption   = true
  }
}

# ========================================================================
# SECTION 2: CONDITIONAL LOCALS
# ========================================================================

locals {
  # Conditional values based on environment
  is_production = var.environment == "production"
  is_development = var.environment == "development"
  
  # Environment-specific settings
  instance_type = local.is_production ? "large" : "small"
  backup_retention = local.is_production ? 30 : 7
  monitoring_interval = local.is_production ? 60 : 300
  
  # Calculated instance count
  actual_instance_count = local.is_production && var.enable_high_availability ? max(var.instance_count, 3) : var.instance_count
  
  # Feature combinations
  enable_advanced_monitoring = var.enable_monitoring && local.is_production
  enable_critical_alerts = var.features["alerting"] && local.is_production
  
  # Dynamic configuration map
  config = {
    development = {
      retention_days = 7
      backup_frequency = "daily"
      instance_type = "t2.micro"
      replicas = 1
    }
    staging = {
      retention_days = 14
      backup_frequency = "twice-daily"
      instance_type = "t2.small"
      replicas = 2
    }
    production = {
      retention_days = 30
      backup_frequency = "hourly"
      instance_type = "t2.medium"
      replicas = 3
    }
  }
  
  # Select configuration based on environment
  env_config = local.config[var.environment]
}

# ========================================================================
# SECTION 3: SIMPLE CONDITIONAL RESOURCES (count)
# ========================================================================

# Resource created only if monitoring is enabled
resource "local_file" "monitoring_config" {
  count = var.enable_monitoring ? 1 : 0
  
  filename = "${path.module}/output/monitoring.yaml"
  content = yamlencode({
    enabled = true
    environment = var.environment
    interval = local.monitoring_interval
    advanced = local.enable_advanced_monitoring
    
    metrics = {
      cpu = true
      memory = true
      disk = true
      network = local.is_production
    }
  })
}

# Multiple resources based on condition
resource "local_file" "backup_configs" {
  count = var.enable_backups ? local.env_config.replicas : 0
  
  filename = "${path.module}/output/backups/backup-${count.index}.conf"
  content = <<-EOT
    # Backup Configuration ${count.index + 1}
    ENABLED=true
    ENVIRONMENT=${var.environment}
    RETENTION_DAYS=${local.env_config.retention_days}
    FREQUENCY=${local.env_config.backup_frequency}
    REPLICA_ID=${count.index}
  EOT
}

# ========================================================================
# SECTION 4: COMPLEX CONDITIONAL RESOURCES (for_each with filtering)
# ========================================================================

# Create resources only for enabled features
resource "local_file" "feature_configs" {
  for_each = {
    for feature, enabled in var.features : 
    feature => enabled if enabled
  }
  
  filename = "${path.module}/output/features/${each.key}.json"
  content = jsonencode({
    feature = each.key
    enabled = each.value
    environment = var.environment
    
    # Feature-specific configuration
    config = {
      logging = each.key == "logging" ? {
        level = local.is_production ? "ERROR" : "DEBUG"
        retention = local.is_production ? 90 : 7
      } : null
      
      metrics = each.key == "metrics" ? {
        interval = local.monitoring_interval
        detailed = local.is_production
      } : null
      
      alerting = each.key == "alerting" ? {
        critical_only = !local.is_production
        channels = local.is_production ? ["email", "sms", "slack"] : ["email"]
      } : null
      
      encryption = each.key == "encryption" ? {
        algorithm = "AES-256"
        key_rotation = local.is_production ? 30 : 90
      } : null
    }
  })
}

# ========================================================================
# SECTION 5: CONDITIONAL RESOURCE ATTRIBUTES
# ========================================================================

resource "local_file" "application_config" {
  filename = "${path.module}/output/app-config.json"
  
  # Conditional content based on environment and features
  content = jsonencode({
    application = {
      name = "conditional-demo"
      environment = var.environment
      version = "1.0.0"
    }
    
    # Include monitoring section only if enabled
    monitoring = var.enable_monitoring ? {
      enabled = true
      interval = local.monitoring_interval
      advanced = local.enable_advanced_monitoring
    } : null
    
    # Include backup section only if enabled
    backup = var.enable_backups ? {
      enabled = true
      retention = local.env_config.retention_days
      frequency = local.env_config.backup_frequency
    } : null
    
    # Dynamic features object
    features = {
      for feature, enabled in var.features :
      feature => {
        enabled = enabled
        production_only = enabled && local.is_production
      }
    }
    
    # Conditional infrastructure settings
    infrastructure = {
      instance_type = local.instance_type
      instance_count = local.actual_instance_count
      high_availability = var.enable_high_availability && local.is_production
      
      # Only include scaling if feature is enabled
      auto_scaling = var.features["auto_scaling"] ? {
        min = local.actual_instance_count
        max = local.actual_instance_count * 3
        target_cpu = 70
      } : null
    }
  })
}

# ========================================================================
# SECTION 6: NESTED CONDITIONAL LOGIC
# ========================================================================

resource "local_file" "instance_configs" {
  count = local.actual_instance_count
  
  filename = "${path.module}/output/instances/instance-${count.index}.yaml"
  content = yamlencode({
    instance = {
      id = count.index
      name = "instance-${var.environment}-${count.index}"
      type = local.instance_type
      
      # Primary only for first instance in production
      role = count.index == 0 && local.is_production ? "primary" : 
             count.index == 0 ? "standalone" :
             local.is_production ? "replica" : "secondary"
      
      # Different settings based on role
      settings = {
        # Production primary gets special treatment
        priority = count.index == 0 && local.is_production ? 100 :
                  count.index == 0 ? 50 : 10
        
        # Monitoring based on environment and role
        monitoring = var.enable_monitoring ? {
          level = count.index == 0 ? "detailed" : "basic"
          alerts = local.enable_critical_alerts && count.index == 0
        } : null
        
        # Backups only for primary or all in production
        backup = var.enable_backups && (count.index == 0 || local.is_production)
      }
    }
  })
}

# ========================================================================
# SECTION 7: CONDITIONAL MODULE-LIKE PATTERN
# ========================================================================

# Simulate module behavior with conditional resource groups
locals {
  deploy_monitoring_stack = var.enable_monitoring && var.features["metrics"] && var.features["alerting"]
  deploy_backup_stack = var.enable_backups && local.is_production
  deploy_ha_stack = var.enable_high_availability && local.is_production && local.actual_instance_count >= 3
}

# Monitoring stack resources
resource "local_file" "monitoring_stack" {
  for_each = local.deploy_monitoring_stack ? {
    "prometheus" = { port = 9090, retention = "15d" }
    "grafana"    = { port = 3000, retention = "30d" }
    "alertmanager" = { port = 9093, retention = "7d" }
  } : {}
  
  filename = "${path.module}/output/monitoring-stack/${each.key}.conf"
  content = <<-EOT
    # ${each.key} Configuration
    SERVICE=${each.key}
    PORT=${each.value.port}
    RETENTION=${each.value.retention}
    ENVIRONMENT=${var.environment}
    PRODUCTION=${local.is_production}
  EOT
}

# Backup stack resources
resource "local_file" "backup_stack" {
  for_each = local.deploy_backup_stack ? {
    "scheduler" = { interval = "1h", type = "cron" }
    "storage"   = { type = "s3", retention = "30d" }
    "validator" = { interval = "24h", type = "checksum" }
  } : {}
  
  filename = "${path.module}/output/backup-stack/${each.key}.yaml"
  content = yamlencode({
    service = each.key
    config = each.value
    environment = var.environment
    critical = local.is_production
  })
}

# ========================================================================
# SECTION 8: DYNAMIC BLOCKS WITH CONDITIONS
# ========================================================================

resource "local_file" "load_balancer_config" {
  filename = "${path.module}/output/load-balancer.conf"
  
  content = <<-EOT
    # Load Balancer Configuration
    # Environment: ${var.environment}
    
    %{ if local.actual_instance_count > 1 ~}
    # Load balancing enabled
    upstream backend {
      %{ for i in range(local.actual_instance_count) ~}
      server instance-${i}:8080 weight=${i == 0 && local.is_production ? 2 : 1};
      %{ endfor ~}
    }
    %{ else ~}
    # Single instance - no load balancing
    upstream backend {
      server instance-0:8080;
    }
    %{ endif ~}
    
    %{ if var.enable_monitoring ~}
    # Monitoring endpoints
    location /metrics {
      proxy_pass http://localhost:9090/metrics;
    }
    %{ endif ~}
    
    %{ if local.enable_critical_alerts ~}
    # Alert webhook endpoint
    location /alerts {
      proxy_pass http://alertmanager:9093/webhook;
    }
    %{ endif ~}
    
    %{ if var.features["encryption"] ~}
    # SSL/TLS Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    %{ endif ~}
  EOT
}

# ========================================================================
# SECTION 9: CONDITIONAL DEPENDENCIES
# ========================================================================

# Resource that depends on conditional resources
resource "local_file" "deployment_summary" {
  filename = "${path.module}/output/DEPLOYMENT_SUMMARY.md"
  
  content = <<-EOT
    # Deployment Summary
    
    ## Environment: ${var.environment}
    
    ## Configuration
    - Instance Count: ${local.actual_instance_count}
    - Instance Type: ${local.instance_type}
    - High Availability: ${var.enable_high_availability ? "Enabled" : "Disabled"}
    
    ## Features
    %{ for feature, enabled in var.features ~}
    - ${feature}: ${enabled ? "✓ Enabled" : "✗ Disabled"}
    %{ endfor ~}
    
    ## Conditional Resources Created
    - Monitoring Config: ${var.enable_monitoring ? "Created" : "Skipped"}
    - Backup Configs: ${var.enable_backups ? "${local.env_config.replicas} created" : "Skipped"}
    - Feature Configs: ${length([for f, e in var.features : f if e])} created
    - Monitoring Stack: ${local.deploy_monitoring_stack ? "Deployed" : "Not deployed"}
    - Backup Stack: ${local.deploy_backup_stack ? "Deployed" : "Not deployed"}
    - HA Stack: ${local.deploy_ha_stack ? "Deployed" : "Not deployed"}
    
    ## Conditional Logic Applied
    - Production Mode: ${local.is_production}
    - Advanced Monitoring: ${local.enable_advanced_monitoring}
    - Critical Alerts: ${local.enable_critical_alerts}
    
    Generated at: ${timestamp()}
  EOT
  
  # Dynamic dependencies based on what was created
  depends_on = [
    local_file.monitoring_config,
    local_file.backup_configs,
    local_file.feature_configs,
    local_file.instance_configs,
    local_file.monitoring_stack,
    local_file.backup_stack
  ]
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "conditional_resources_created" {
  description = "Summary of conditionally created resources"
  value = {
    monitoring = {
      enabled = var.enable_monitoring
      config_created = var.enable_monitoring ? 1 : 0
      advanced = local.enable_advanced_monitoring
    }
    
    backups = {
      enabled = var.enable_backups
      configs_created = var.enable_backups ? local.env_config.replicas : 0
      stack_deployed = local.deploy_backup_stack
    }
    
    features = {
      total = length(var.features)
      enabled = length([for f, e in var.features : f if e])
      configs_created = length(local_file.feature_configs)
    }
    
    instances = {
      requested = var.instance_count
      actual = local.actual_instance_count
      configs_created = length(local_file.instance_configs)
    }
    
    stacks = {
      monitoring = local.deploy_monitoring_stack ? 3 : 0
      backup = local.deploy_backup_stack ? 3 : 0
      total = (local.deploy_monitoring_stack ? 3 : 0) + (local.deploy_backup_stack ? 3 : 0)
    }
  }
}

output "environment_settings" {
  description = "Environment-specific settings applied"
  value = {
    environment = var.environment
    is_production = local.is_production
    config_applied = local.env_config
    
    conditional_features = {
      advanced_monitoring = local.enable_advanced_monitoring
      critical_alerts = local.enable_critical_alerts
      ha_stack = local.deploy_ha_stack
    }
  }
}

output "conditional_patterns_demonstrated" {
  description = "Conditional patterns shown in this exercise"
  value = <<-EOT
    
    CONDITIONAL PATTERNS DEMONSTRATED:
    
    1. Simple Conditionals:
       - count = condition ? 1 : 0
       - Basic if/then resource creation
    
    2. Complex Conditionals:
       - for_each with filtering
       - Nested conditional logic
       - Multiple condition combinations
    
    3. Conditional Attributes:
       - Dynamic content based on variables
       - Optional sections in JSON/YAML
       - Conditional dependencies
    
    4. Environment-Based Logic:
       - Different settings per environment
       - Production vs development features
       - Environment-specific resources
    
    5. Feature Flags:
       - Enable/disable functionality
       - Feature-specific configuration
       - Dependent feature logic
    
    6. Dynamic Resource Groups:
       - Conditional "stacks" of resources
       - Module-like patterns
       - Related resource dependencies
    
    7. Advanced Techniques:
       - Conditional locals
       - Dynamic blocks with conditions
       - Calculated resource counts
    
    PowerShell Comparison:
       Terraform: count = var.enabled ? 1 : 0
       PowerShell: if ($Enabled) { New-Resource }
    
  EOT
}