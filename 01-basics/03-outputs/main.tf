# ╔════════════════════════════════════════════════════════════════════╗
# ║  TERRAFORM OUTPUTS - EXPOSING AND SHARING DATA                      ║
# ║  Learn how outputs work and how to share data between configs       ║
# ╚════════════════════════════════════════════════════════════════════╝

# WHAT YOU'LL LEARN:
# ==================
# 1. All output types (string, number, bool, list, map, object)
# 2. Sensitive outputs for handling secrets
# 3. Conditional outputs based on variables
# 4. Complex computed outputs
# 5. Formatted outputs for better readability
# 6. Outputs for sharing between configurations
# 7. Using outputs with terraform output command

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
# SECTION 1: RESOURCES TO OUTPUT
# ========================================================================
# First, let's create resources whose values we'll output

# Generate random values to demonstrate outputs
resource "random_id" "server_id" {
  byte_length = 4
}

resource "random_password" "db_password" {
  length  = 16
  special = true
  # This will be marked sensitive automatically
}

resource "random_pet" "server_name" {
  prefix = var.environment
  length = 2
}

resource "random_integer" "port" {
  min = 8000
  max = 8999
}

# Create a configuration file
resource "local_file" "app_config" {
  filename = "./terraform-lab-output/app-config.json"
  content = jsonencode({
    server = {
      id   = random_id.server_id.hex
      name = random_pet.server_name.id
      port = random_integer.port.result
    }
    environment = var.environment
    project     = var.project_name
    created_at  = timestamp()
    team        = var.team_members
    features = {
      monitoring = var.enable_monitoring
      backups    = var.enable_backups
      debug      = var.environment != "production"
    }
  })
}

# Create multiple server configs using count
resource "local_file" "server_configs" {
  count    = var.server_count
  filename = "./terraform-lab-output/servers/server-${count.index + 1}.yaml"
  
  content = yamlencode({
    server = {
      index    = count.index
      id       = "${random_id.server_id.hex}-${count.index + 1}"
      name     = "${random_pet.server_name.id}-${count.index + 1}"
      ip       = "10.0.1.${count.index + 10}"
      port     = random_integer.port.result + count.index
      role     = element(var.server_roles, count.index)
      primary  = count.index == 0
    }
  })
}

# Create environment-specific configs using for_each
resource "local_file" "environment_configs" {
  for_each = toset(var.environments)
  
  filename = "./terraform-lab-output/envs/${each.value}.conf"
  content  = <<-EOT
    # Environment: ${each.value}
    # Generated: ${timestamp()}
    
    [environment]
    name = ${each.value}
    is_production = ${each.value == "production"}
    
    [database]
    host = ${each.value}-db.${var.domain}
    port = 5432
    ssl_required = ${each.value == "production"}
    
    [features]
    debug = ${each.value != "production"}
    monitoring = true
    backup_enabled = ${each.value == "production" || var.enable_backups}
  EOT
}

# Create a monitoring config if enabled
resource "local_file" "monitoring_config" {
  count = var.enable_monitoring ? 1 : 0
  
  filename = "./terraform-lab-output/monitoring.json"
  content = jsonencode({
    enabled = true
    project = var.project_name
    environment = var.environment
    endpoints = [
      for i in range(var.server_count) : {
        name = "${random_pet.server_name.id}-${i + 1}"
        url  = "http://10.0.1.${i + 10}:${random_integer.port.result + i}/health"
      }
    ]
    alert_email = "ops@${var.domain}"
  })
}

# Create a summary file
resource "local_file" "infrastructure_summary" {
  filename = "./terraform-lab-output/INFRASTRUCTURE_SUMMARY.md"
  content  = templatefile("${path.module}/templates/summary.tftpl", {
    project_name   = var.project_name
    environment    = var.environment
    server_count   = var.server_count
    server_name    = random_pet.server_name.id
    server_id      = random_id.server_id.hex
    port           = random_integer.port.result
    team_members   = var.team_members
    environments   = var.environments
    monitoring     = var.enable_monitoring
    backups        = var.enable_backups
    timestamp      = timestamp()
    domain         = var.domain
  })
}

# ========================================================================
# SECTION 2: LOCAL VALUES FOR COMPUTED DATA
# ========================================================================

locals {
  # Basic computed values
  project_id = "${var.project_name}-${var.environment}-${random_id.server_id.hex}"
  
  # Server information collection
  servers = [
    for i in range(var.server_count) : {
      index = i
      id    = "${random_id.server_id.hex}-${i + 1}"
      name  = "${random_pet.server_name.id}-${i + 1}"
      ip    = "10.0.1.${i + 10}"
      port  = random_integer.port.result + i
      role  = element(var.server_roles, i)
      url   = "http://10.0.1.${i + 10}:${random_integer.port.result + i}"
    }
  ]
  
  # Environment configuration mapping
  env_configs = {
    for env in var.environments : env => {
      is_production = env == "production"
      db_host       = "${env}-db.${var.domain}"
      debug_enabled = env != "production"
      file_path     = "./terraform-lab-output/envs/${env}.conf"
    }
  }
  
  # Statistics
  total_files_created = (
    1 +                                    # app_config
    var.server_count +                     # server_configs
    length(var.environments) +             # environment_configs
    (var.enable_monitoring ? 1 : 0) +      # monitoring_config
    1                                      # infrastructure_summary
  )
  
  # Tags for resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
    ServerID    = random_id.server_id.hex
  }
}

# ========================================================================
# SECTION 3: CREATE TEMPLATE FILE
# ========================================================================

resource "local_file" "template" {
  filename = "${path.module}/templates/summary.tftpl"
  content  = <<-EOT
    # Infrastructure Summary Report
    
    ## Project Information
    - **Project Name**: $${project_name}
    - **Environment**: $${environment}
    - **Domain**: $${domain}
    - **Generated**: $${timestamp}
    
    ## Server Configuration
    - **Server Base Name**: $${server_name}
    - **Server ID**: $${server_id}
    - **Server Count**: $${server_count}
    - **Base Port**: $${port}
    
    ## Team Members
    %{ for member in team_members ~}
    - $${member}
    %{ endfor ~}
    
    ## Configured Environments
    %{ for env in environments ~}
    - $${env}
    %{ endfor ~}
    
    ## Features
    - Monitoring: $${monitoring ? "Enabled" : "Disabled"}
    - Backups: $${backups ? "Enabled" : "Disabled"}
    
    ## Files Created
    - Main configuration: app-config.json
    - Server configurations: $${server_count} files
    - Environment configurations: $${length(environments)} files
    %{ if monitoring ~}
    - Monitoring configuration: monitoring.json
    %{ endif ~}
    
    ---
    *This report was automatically generated by Terraform*
  EOT
}