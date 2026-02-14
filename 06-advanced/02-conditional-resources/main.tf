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
  
  filename = "./terraform-lab-output/monitoring.yaml"
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
  
  filename = "./terraform-lab-output/backups/backup-${count.index}.conf"
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
  
  filename = "./terraform-lab-output/features/${each.key}.json"
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
  filename = "./terraform-lab-output/app-config.json"
  
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
  
  filename = "./terraform-lab-output/instances/instance-${count.index}.yaml"
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
  
  filename = "./terraform-lab-output/monitoring-stack/${each.key}.conf"
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
  
  filename = "./terraform-lab-output/backup-stack/${each.key}.yaml"
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
  filename = "./terraform-lab-output/load-balancer.conf"
  
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
  filename = "./terraform-lab-output/DEPLOYMENT_SUMMARY.md"
  
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
# POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-conditionals.ps1"
  
  content = <<-EOT
    # PowerShell Equivalent of Terraform Conditional Resources
    # =========================================================
    # This shows how Terraform conditionals compare to PowerShell logic
    
    Write-Host "=== Terraform Conditionals vs PowerShell If/Switch ===" -ForegroundColor Green
    
    # VARIABLES (like Terraform variables)
    $EnableMonitoring = $true
    $Environment = "production"
    $InstanceCount = 3
    $Features = @{
        logging = $true
        metrics = $true
        alerts = $false
        backup = $true
    }
    
    # TERRAFORM: count = var.enable_monitoring ? 1 : 0
    # POWERSHELL EQUIVALENT:
    Write-Host "`nConditional Resource Creation (count pattern):" -ForegroundColor Yellow
    
    if ($EnableMonitoring) {
        # Create monitoring config (like count = 1)
        $monitoringConfig = @{
            enabled = $true
            environment = $Environment
            interval = if ($Environment -eq "production") { 60 } else { 300 }
        }
        $monitoringConfig | ConvertTo-Json | Set-Content "./terraform-lab-output/monitoring.json"
        Write-Host "  Created monitoring config"
    } else {
        Write-Host "  Skipped monitoring config (disabled)"
    }
    
    # TERRAFORM: count = var.instance_count
    # POWERSHELL EQUIVALENT:
    Write-Host "`nMultiple Resources (count with number):" -ForegroundColor Yellow
    
    1..$InstanceCount | ForEach-Object {
        $instance = @{
            id = $_
            name = "instance-$_"
            environment = $Environment
            role = if ($_ -eq 1 -and $Environment -eq "production") { "primary" } else { "replica" }
        }
        $instance | ConvertTo-Json | Set-Content "./terraform-lab-output/instance-$_.json"
        Write-Host "  Created instance-$_"
    }
    
    # TERRAFORM: for_each with conditional
    # POWERSHELL EQUIVALENT:
    Write-Host "`nConditional For Each (filtered resources):" -ForegroundColor Yellow
    
    $Features.GetEnumerator() | Where-Object { $_.Value -eq $true } | ForEach-Object {
        $featureConfig = @{
            feature = $_.Key
            enabled = $true
            environment = $Environment
            config = switch ($_.Key) {
                "logging" { @{ level = "info"; retention = "30d" } }
                "metrics" { @{ interval = 60; aggregation = "avg" } }
                "backup" { @{ frequency = "daily"; retention = "7d" } }
                default { @{} }
            }
        }
        $featureConfig | ConvertTo-Json | Set-Content "./terraform-lab-output/feature-$($_.Key).json"
        Write-Host "  Created feature config: $($_.Key)"
    }
    
    # TERRAFORM: Conditional expressions in resource attributes
    # POWERSHELL EQUIVALENT:
    Write-Host "`nConditional Attributes:" -ForegroundColor Yellow
    
    $appConfig = @{
        name = "conditional-demo"
        environment = $Environment
        
        # Conditional values (like Terraform's condition ? true_val : false_val)
        debug = if ($Environment -eq "development") { $true } else { $false }
        replicas = if ($Environment -eq "production") { 3 } else { 1 }
        
        # Complex conditions
        monitoring = @{
            enabled = $EnableMonitoring
            level = switch ($Environment) {
                "production" { "detailed" }
                "staging" { "standard" }
                default { "basic" }
            }
        }
        
        # Conditional nested objects (like Terraform's dynamic blocks)
        features = foreach ($feature in $Features.GetEnumerator()) {
            if ($feature.Value) {
                @{
                    name = $feature.Key
                    enabled = $true
                }
            }
        } | Where-Object { $_ -ne $null }
    }
    
    $appConfig | ConvertTo-Json -Depth 10 | Set-Content "./terraform-lab-output/app-config.json"
    Write-Host "  Created app config with conditional attributes"
    
    # TERRAFORM: lookup() and try()
    # POWERSHELL EQUIVALENT:
    Write-Host "`nSafe Lookups and Defaults:" -ForegroundColor Yellow
    
    $envConfigs = @{
        production = @{ instances = 5; monitoring = "detailed" }
        staging = @{ instances = 2; monitoring = "standard" }
        development = @{ instances = 1; monitoring = "basic" }
    }
    
    # Safe lookup with default (like Terraform's lookup())
    $currentConfig = if ($envConfigs.ContainsKey($Environment)) { 
        $envConfigs[$Environment] 
    } else { 
        @{ instances = 1; monitoring = "basic" }
    }
    
    Write-Host "  Environment config: $($currentConfig | ConvertTo-Json -Compress)"
    
    # Try pattern (like Terraform's try())
    function Safe-Get {
        param($ScriptBlock, $Default)
        try {
            & $ScriptBlock
        } catch {
            $Default
        }
    }
    
    $safeLookup = Safe-Get { $envConfigs.production.instances } 1
    Write-Host "  Safe lookup result: $safeLookup"
    
    # TERRAFORM: Conditional module calls
    # POWERSHELL EQUIVALENT:
    Write-Host "`nConditional Function Calls (like conditional modules):" -ForegroundColor Yellow
    
    function Deploy-MonitoringStack {
        Write-Host "    Deploying monitoring stack..."
        # Implementation here
    }
    
    function Deploy-BackupSystem {
        Write-Host "    Deploying backup system..."
        # Implementation here
    }
    
    # Conditional execution
    if ($Environment -eq "production" -or $EnableMonitoring) {
        Deploy-MonitoringStack
    }
    
    if ($Features.backup -and $Environment -ne "development") {
        Deploy-BackupSystem
    }
    
    # COMPLEX CONDITIONS
    Write-Host "`nComplex Conditional Logic:" -ForegroundColor Yellow
    
    # Nested conditions (like Terraform's nested conditionals)
    $deploymentConfig = @{
        highAvailability = (
            $Environment -eq "production" -and 
            $InstanceCount -gt 1
        )
        
        backupEnabled = (
            $Features.backup -and
            $Environment -ne "development"
        )
        
        monitoringLevel = if ($Environment -eq "production") {
            if ($EnableMonitoring) { "full" } else { "basic" }
        } elseif ($Environment -eq "staging") {
            "standard"
        } else {
            "minimal"
        }
    }
    
    Write-Host "  Deployment config: $($deploymentConfig | ConvertTo-Json -Compress)"
    
    # KEY DIFFERENCES:
    Write-Host "`n=== Key Differences ===" -ForegroundColor Magenta
    Write-Host @"
    1. DECLARATIVE vs IMPERATIVE:
       - Terraform: Declares desired conditional state
       - PowerShell: Executes conditional logic procedurally
    
    2. RESOURCE CREATION:
       - Terraform: count = condition ? 1 : 0
       - PowerShell: if (condition) { create-resource }
    
    3. MULTIPLE RESOURCES:
       - Terraform: count = number
       - PowerShell: 1..number | ForEach-Object
    
    4. FOR EACH WITH CONDITIONS:
       - Terraform: for_each = { for k,v in map : k => v if condition }
       - PowerShell: $map | Where-Object { condition } | ForEach-Object
    
    5. CONDITIONAL EXPRESSIONS:
       - Terraform: attribute = condition ? true_val : false_val
       - PowerShell: attribute = if (condition) { true_val } else { false_val }
    
    6. NULL HANDLING:
       - Terraform: Unset attributes are omitted
       - PowerShell: Must explicitly handle $null values
    
    7. TYPE SAFETY:
       - Terraform: Type checking at plan time
       - PowerShell: Runtime type checking
    
    8. STATE TRACKING:
       - Terraform: Tracks conditional resources in state
       - PowerShell: No automatic state for conditions
    "@
    
    Write-Host "`nTerraform's declarative conditionals ensure idempotent infrastructure!" -ForegroundColor Green
  EOT
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