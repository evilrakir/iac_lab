# Exercise 5: Resources - Creating and Managing Infrastructure
# Learn about resource lifecycle, dependencies, and advanced resource patterns

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
  required_version = ">= 1.0"
}

# Variables for our resource examples
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "resource-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "server_count" {
  description = "Number of servers to create"
  type        = number
  default     = 3
  
  validation {
    condition     = var.server_count >= 1 && var.server_count <= 10
    error_message = "Server count must be between 1 and 10."
  }
}

variable "enable_backup" {
  description = "Enable backup configuration"
  type        = bool
  default     = true
}

variable "server_config" {
  description = "Server configuration map"
  type = map(object({
    cpu    = string
    memory = string
    role   = string
  }))
  default = {
    web = {
      cpu    = "2"
      memory = "4GB"
      role   = "webserver"
    }
    api = {
      cpu    = "4"
      memory = "8GB"
      role   = "api"
    }
    db = {
      cpu    = "8"
      memory = "16GB"
      role   = "database"
    }
  }
}

# Local values for computed data
locals {
  # Create a unique project identifier
  project_id = "${var.project_name}-${var.environment}"
  
  # Generate timestamp for resource creation
  creation_time = timestamp()
  
  # Common tags for all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", local.creation_time)
  }
  
  # Generate server names
  server_names = [
    for i in range(var.server_count) : "${local.project_id}-server-${format("%02d", i + 1)}"
  ]
  
  # Create network configuration
  network_config = {
    subnet_base = "10.0.0.0"
    cidr_block  = "10.0.0.0/16"
    subnets = [
      for i in range(3) : {
        name = "subnet-${i + 1}"
        cidr = "10.0.${i + 1}.0/24"
      }
    ]
  }
}

# RESOURCE EXAMPLES - Demonstrating different resource patterns

# 1. Basic Resource Creation
resource "local_file" "project_readme" {
  filename = "${path.module}/infrastructure/${local.project_id}/README.md"
  content = <<-EOF
    # ${var.project_name} Infrastructure
    
    Project: ${var.project_name}
    Environment: ${var.environment}
    Created: ${local.creation_time}
    
    ## Infrastructure Overview
    - Servers: ${var.server_count}
    - Backup Enabled: ${var.enable_backup}
    - Server Types: ${length(var.server_config)}
    
    ## Network Configuration
    - Base Network: ${local.network_config.subnet_base}
    - CIDR Block: ${local.network_config.cidr_block}
    - Subnets: ${length(local.network_config.subnets)}
    
    ## Tags
    %{ for key, value in local.common_tags ~}
    - ${key}: ${value}
    %{ endfor ~}
  EOF
}

# 2. Resource with Dependencies (explicit)
resource "local_file" "network_config" {
  filename = "${path.module}/infrastructure/${local.project_id}/network.json"
  content = jsonencode({
    project_id     = local.project_id
    network        = local.network_config
    created_after  = local_file.project_readme.filename
    tags          = local.common_tags
  })
  
  # Explicit dependency - this resource waits for project_readme
  depends_on = [local_file.project_readme]
}

# 3. Resource with Count (creating multiple similar resources)
resource "local_file" "server_configs" {
  count = var.server_count
  
  filename = "${path.module}/infrastructure/${local.project_id}/servers/server-${format("%02d", count.index + 1)}.conf"
  content = <<-EOF
    # Server Configuration ${count.index + 1}
    [server]
    name=${local.server_names[count.index]}
    index=${count.index + 1}
    role=application-server
    
    [network]
    subnet=${local.network_config.subnets[count.index % 3].name}
    cidr=${local.network_config.subnets[count.index % 3].cidr}
    
    [resources]
    cpu=2
    memory=4GB
    
    [metadata]
    project=${var.project_name}
    environment=${var.environment}
    created=${local.creation_time}
  EOF
  
  # Implicit dependency - references local_file.network_config
  depends_on = [local_file.network_config]
}

# 4. Resource with for_each (creating resources from a map)
resource "local_file" "service_configs" {
  for_each = var.server_config
  
  filename = "${path.module}/infrastructure/${local.project_id}/services/${each.key}.yaml"
  content = yamlencode({
    service = {
      name = each.key
      role = each.value.role
      resources = {
        cpu    = each.value.cpu
        memory = each.value.memory
      }
    }
    project = {
      id          = local.project_id
      name        = var.project_name
      environment = var.environment
    }
    network = {
      subnet = local.network_config.subnets[0].name
      cidr   = local.network_config.subnets[0].cidr
    }
    metadata = local.common_tags
  })
}

# 5. Conditional Resource (created only if condition is met)
resource "local_file" "backup_config" {
  count = var.enable_backup ? 1 : 0
  
  filename = "${path.module}/infrastructure/${local.project_id}/backup.json"
  content = jsonencode({
    backup = {
      enabled   = true
      schedule  = "0 2 * * *"  # Daily at 2 AM
      retention = "30d"
      targets   = local.server_names
    }
    project = local.project_id
    created = local.creation_time
    tags    = local.common_tags
  })
}

# 6. Null Resource (for running provisioners or external commands)
resource "null_resource" "infrastructure_validation" {
  # Triggers determine when this resource should be recreated
  triggers = {
    server_count     = var.server_count
    project_id       = local.project_id
    config_checksum  = md5(jsonencode(var.server_config))
  }
  
  # Local provisioner - runs on the machine running Terraform
  provisioner "local-exec" {
    command = <<-EOT
      echo "Infrastructure validation started"
      echo "Project: ${local.project_id}"
      echo "Servers: ${var.server_count}"
      echo "Services: ${length(var.server_config)}"
      echo "Backup enabled: ${var.enable_backup}"
      echo "Validation completed successfully"
    EOT
    
    interpreter = ["PowerShell", "-Command"]
  }
  
  # This runs when the resource is destroyed
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Infrastructure cleanup initiated'"
    interpreter = ["PowerShell", "-Command"]
  }
  
  # Dependencies - this runs after other resources are created
  depends_on = [
    local_file.server_configs,
    local_file.service_configs,
    local_file.network_config
  ]
}

# 7. Resource with Lifecycle Rules
resource "local_file" "persistent_config" {
  filename = "${path.module}/infrastructure/${local.project_id}/persistent.json"
  content = jsonencode({
    config = {
      version = "1.0"
      project = local.project_id
      persistent_data = "This file should not be replaced"
    }
    last_updated = local.creation_time
  })
  
  # Lifecycle rules
  lifecycle {
    # Prevent this resource from being destroyed
    prevent_destroy = false  # Set to true in production
    
    # Create new resource before destroying old one
    create_before_destroy = true
    
    # Ignore changes to certain attributes
    ignore_changes = [
      # content  # Uncomment to ignore content changes
    ]
  }
}

# 8. Sensitive Resource (for handling sensitive data)
resource "local_sensitive_file" "secrets" {
  filename = "${path.module}/infrastructure/${local.project_id}/.secrets"
  content = jsonencode({
    database = {
      password = "super-secret-password"
      api_key  = "secret-api-key-12345"
    }
    project = local.project_id
    note = "This file contains sensitive information"
  })
  
  # This file will have restricted permissions (0600)
}

# 9. Dynamic Blocks Example (creating multiple sub-blocks)
resource "local_file" "load_balancer_config" {
  filename = "${path.module}/infrastructure/${local.project_id}/load-balancer.conf"
  content = <<-EOF
    # Load Balancer Configuration for ${local.project_id}
    
    upstream backend {
      %{ for i, server in local.server_names ~}
      server ${server}:8080 weight=1;
      %{ endfor ~}
    }
    
    %{ for service_name, config in var.server_config ~}
    upstream ${service_name}_backend {
      server ${service_name}.local:8080;
    }
    %{ endfor ~}
    
    server {
      listen 80;
      server_name ${local.project_id}.local;
      
      location / {
        proxy_pass http://backend;
      }
      
      %{ for service_name, config in var.server_config ~}
      location /${service_name}/ {
        proxy_pass http://${service_name}_backend/;
      }
      %{ endfor ~}
    }
  EOF
}

# 10. Data Processing Resource
resource "local_file" "infrastructure_summary" {
  filename = "${path.module}/infrastructure/${local.project_id}/SUMMARY.json"
  content = jsonencode({
    project = {
      id          = local.project_id
      name        = var.project_name
      environment = var.environment
    }
    
    infrastructure = {
      servers = {
        count = var.server_count
        names = local.server_names
      }
      services = {
        count = length(var.server_config)
        types = keys(var.server_config)
      }
      network = {
        base_cidr = local.network_config.cidr_block
        subnets   = length(local.network_config.subnets)
      }
    }
    
    features = {
      backup_enabled = var.enable_backup
      services_count = length(var.server_config)
    }
    
    metadata = {
      created_at    = local.creation_time
      tags          = local.common_tags
      terraform_version = ">= 1.0"
    }
    
    # Resource counts
    resources_created = {
      total_files       = var.server_count + length(var.server_config) + 6 + (var.enable_backup ? 1 : 0)
      server_configs    = var.server_count
      service_configs   = length(var.server_config)
      backup_configs    = var.enable_backup ? 1 : 0
      network_configs   = 1
      summary_files     = 3
    }
  })
  
  # This should be created last
  depends_on = [
    local_file.server_configs,
    local_file.service_configs,
    local_file.network_config,
    local_file.backup_config,
    null_resource.infrastructure_validation
  ]
}


# Outputs showing resource information
output "resource_summary" {
  description = "Summary of all created resources"
  value = {
    project_info = {
      id          = local.project_id
      name        = var.project_name
      environment = var.environment
    }
    
    resources_created = {
      server_configs  = length(local_file.server_configs)
      service_configs = length(local_file.service_configs)
      backup_enabled  = var.enable_backup
      total_files     = var.server_count + length(var.server_config) + 6 + (var.enable_backup ? 1 : 0)
    }
    
    infrastructure = {
      servers = local.server_names
      services = keys(var.server_config)
      network_subnets = [for subnet in local.network_config.subnets : subnet.name]
    }
  }
}

output "file_locations" {
  description = "Locations of created configuration files"
  value = {
    project_readme   = local_file.project_readme.filename
    network_config   = local_file.network_config.filename
    server_configs   = [for config in local_file.server_configs : config.filename]
    service_configs  = {for k, v in local_file.service_configs : k => v.filename}
    backup_config    = var.enable_backup ? local_file.backup_config[0].filename : "backup disabled"
    summary_file     = local_file.infrastructure_summary.filename
  }
}

output "resource_dependencies" {
  description = "Demonstration of how resources depend on each other"
  value = <<-EOT
    
    RESOURCE DEPENDENCY CHAIN:
    
    1. project_readme (created first)
       ↓
    2. network_config (depends on project_readme)
       ↓
    3. server_configs (depends on network_config)
       │
       ├── service_configs (created in parallel)
       └── backup_config (conditional)
       ↓
    4. infrastructure_validation (depends on configs)
       ↓
    5. infrastructure_summary (created last)
    
    This demonstrates:
    - Explicit dependencies (depends_on)
    - Implicit dependencies (resource references)
    - Conditional resources (count = condition ? 1 : 0)
    - Resource lifecycle management
    
  EOT
}