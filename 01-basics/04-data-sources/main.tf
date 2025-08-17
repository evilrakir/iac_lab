# Exercise 4: Data Sources - Reading Existing Information
# Learn how to use data sources to fetch information about existing resources

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

# Variables for configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "data-sources-demo"
}

variable "config_file_name" {
  description = "Name of the config file to read"
  type        = string
  default     = "app-config.json"
}

# First, let's create some files that we can then read with data sources
# This simulates existing infrastructure or configuration files

resource "local_file" "app_config" {
  filename = "${path.module}/data/${var.config_file_name}"
  content = jsonencode({
    application = {
      name    = var.project_name
      version = "1.2.3"
      port    = 8080
      database = {
        host = "localhost"
        port = 5432
        name = "appdb"
      }
    }
    features = {
      authentication = true
      monitoring     = true
      logging        = true
      caching        = false
    }
    environment = {
      type = "development"
      region = "us-east-1"
      zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  })
}

resource "local_file" "server_list" {
  filename = "${path.module}/data/servers.csv"
  content = <<-EOF
    hostname,ip_address,role,environment,status
    web-01,10.0.1.10,webserver,development,active
    web-02,10.0.1.11,webserver,development,active
    db-01,10.0.1.20,database,development,active
    cache-01,10.0.1.30,cache,development,maintenance
    api-01,10.0.1.40,api,development,active
  EOF
}

resource "local_file" "secrets_template" {
  filename = "${path.module}/data/secrets.env"
  content = <<-EOF
    # Environment secrets template
    DB_PASSWORD=changeme123
    API_KEY=sk-test-1234567890
    REDIS_PASSWORD=redis-secret
    JWT_SECRET=jwt-signing-key
  EOF
}

# Create a directory listing file
resource "local_file" "directory_manifest" {
  filename = "${path.module}/data/manifest.txt"
  content = <<-EOF
    # Directory contents for ${var.project_name}
    ${var.config_file_name}
    servers.csv
    secrets.env
    manifest.txt
  EOF
  
  depends_on = [
    local_file.app_config,
    local_file.server_list,
    local_file.secrets_template
  ]
}

# DATA SOURCES - This is what this exercise focuses on!
# Data sources allow you to read information from existing resources

# 1. Reading a JSON configuration file
data "local_file" "existing_config" {
  filename = local_file.app_config.filename
  
  # This depends_on ensures the file exists before trying to read it
  depends_on = [local_file.app_config]
}

# 2. Reading a CSV file with server information
data "local_file" "server_inventory" {
  filename = local_file.server_list.filename
  depends_on = [local_file.server_list]
}

# 3. Reading secrets/environment file
data "local_file" "environment_secrets" {
  filename = local_file.secrets_template.filename
  depends_on = [local_file.secrets_template]
}

# 4. Reading directory manifest
data "local_file" "directory_contents" {
  filename = local_file.directory_manifest.filename
  depends_on = [local_file.directory_manifest]
}

# Local values to process the data we read
locals {
  # Parse the JSON configuration
  app_config = jsondecode(data.local_file.existing_config.content)
  
  # Process the CSV data (simplified - in reality you'd use a CSV parser)
  server_lines = split("\n", trimspace(data.local_file.server_inventory.content))
  server_headers = split(",", local.server_lines[0])
  
  # Create a map of active servers (filtering out the header and inactive ones)
  active_servers = {
    for line in slice(local.server_lines, 1, length(local.server_lines)) :
    split(",", line)[0] => {
      hostname    = split(",", line)[0]
      ip_address  = split(",", line)[1]
      role        = split(",", line)[2]
      environment = split(",", line)[3]
      status      = split(",", line)[4]
    }
    if length(split(",", line)) >= 5 && split(",", line)[4] != "maintenance"
  }
  
  # Extract environment variables from the secrets file
  secret_lines = [
    for line in split("\n", data.local_file.environment_secrets.content) :
    line if length(line) > 0 && !startswith(trimspace(line), "#")
  ]
  
  # Parse environment variables
  environment_vars = {
    for line in local.secret_lines :
    split("=", line)[0] => split("=", line)[1]
    if length(split("=", line)) == 2
  }
}

# Create new resources based on the data we read
resource "local_file" "processed_config" {
  filename = "${path.module}/output/processed-config.json"
  content = jsonencode({
    # Use data from the existing config
    source_application = local.app_config.application.name
    source_version     = local.app_config.application.version
    
    # Processed server information
    infrastructure = {
      active_servers = local.active_servers
      server_count   = length(local.active_servers)
      roles = distinct([
        for server in local.active_servers : server.role
      ])
    }
    
    # Environment configuration
    environment = {
      type   = local.app_config.environment.type
      region = local.app_config.environment.region
      zones  = local.app_config.environment.zones
    }
    
    # Feature flags from config
    features_enabled = [
      for feature, enabled in local.app_config.features : feature
      if enabled
    ]
    
    # Metadata
    processed_at = timestamp()
    data_sources = {
      config_file   = data.local_file.existing_config.filename
      server_file   = data.local_file.server_inventory.filename
      secrets_file  = data.local_file.environment_secrets.filename
    }
  })
}

# Create server-specific configuration files
resource "local_file" "server_configs" {
  for_each = local.active_servers
  
  filename = "${path.module}/output/server-${each.key}.conf"
  content = <<-EOF
    # Server configuration for ${each.value.hostname}
    # Generated from data source: ${data.local_file.server_inventory.filename}
    
    [server]
    hostname=${each.value.hostname}
    ip_address=${each.value.ip_address}
    role=${each.value.role}
    environment=${each.value.environment}
    status=${each.value.status}
    
    [application]
    name=${local.app_config.application.name}
    version=${local.app_config.application.version}
    port=${local.app_config.application.port}
    
    [database]
    host=${local.app_config.application.database.host}
    port=${local.app_config.application.database.port}
    name=${local.app_config.application.database.name}
    
    [features]
    %{ for feature, enabled in local.app_config.features ~}
    ${feature}=${enabled}
    %{ endfor ~}
  EOF
}

# Outputs to show what we learned from data sources
output "original_config_summary" {
  description = "Summary of data read from the original config file"
  value = {
    app_name     = local.app_config.application.name
    app_version  = local.app_config.application.version
    app_port     = local.app_config.application.port
    environment  = local.app_config.environment.type
    region       = local.app_config.environment.region
    features     = local.app_config.features
  }
}

output "server_inventory_summary" {
  description = "Summary of servers read from CSV file"
  value = {
    total_servers  = length(local.active_servers)
    active_servers = keys(local.active_servers)
    server_roles   = distinct([for server in local.active_servers : server.role])
  }
}

output "data_source_files" {
  description = "Files that were read as data sources"
  value = {
    config_file = {
      path = data.local_file.existing_config.filename
      size = length(data.local_file.existing_config.content)
    }
    server_file = {
      path = data.local_file.server_inventory.filename
      size = length(data.local_file.server_inventory.content)
    }
    secrets_file = {
      path = data.local_file.environment_secrets.filename
      size = length(data.local_file.environment_secrets.content)
    }
  }
}

output "processed_data" {
  description = "Example of how data sources can be processed and used"
  value = {
    servers_by_role = {
      for role in distinct([for server in local.active_servers : server.role]) :
      role => [
        for server in local.active_servers : server.hostname
        if server.role == role
      ]
    }
    
    environment_vars_count = length(local.environment_vars)
    
    features_enabled = [
      for feature, enabled in local.app_config.features : feature
      if enabled
    ]
    
    generated_files = length(local.active_servers) + 1  # server configs + processed config
  }
}

# Sensitive output showing environment variables (be careful with secrets!)
output "environment_variables" {
  description = "Environment variables read from secrets file"
  value       = local.environment_vars
  sensitive   = true
}

output "data_sources_explanation" {
  description = "Explanation of what data sources demonstrated"
  value = <<-EOT
    
    DATA SOURCES DEMONSTRATION:
    
    This exercise showed how to:
    1. Read existing files using 'data "local_file"' blocks
    2. Parse JSON data with jsondecode()
    3. Process CSV-like data with string functions
    4. Extract configuration from various file formats
    5. Use data source content to create new resources
    6. Transform and filter data from external sources
    
    Data sources are commonly used to:
    - Read existing AWS resources (VPCs, subnets, AMIs)
    - Get information about DNS records
    - Fetch secrets from external systems
    - Read configuration from external files
    - Integrate with existing infrastructure
    
    Files read in this demo:
    - ${data.local_file.existing_config.filename} (JSON config)
    - ${data.local_file.server_inventory.filename} (CSV data)
    - ${data.local_file.environment_secrets.filename} (environment vars)
    - ${data.local_file.directory_contents.filename} (manifest)
    
  EOT
}