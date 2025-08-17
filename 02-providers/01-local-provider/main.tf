# Exercise: Local Provider - Understanding Terraform Providers
# Learn about providers and explore the local provider in depth

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

# Variables for the exercise
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "local-provider-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "team_size" {
  description = "Number of team members"
  type        = number
  default     = 5
}

variable "create_sensitive_files" {
  description = "Whether to create sensitive files"
  type        = bool
  default     = true
}

# Local values
locals {
  project_id = "${var.project_name}-${var.environment}"
  timestamp = timestamp()
  
  # Team member data
  team_members = [
    for i in range(var.team_size) : {
      id       = i + 1
      name     = "team-member-${i + 1}"
      email    = "member${i + 1}@company.com"
      role     = i == 0 ? "lead" : "developer"
    }
  ]
  
  # Configuration data
  app_config = {
    name        = var.project_name
    environment = var.environment
    version     = "1.0.0"
    team_size   = var.team_size
    created_at  = local.timestamp
  }
}

# PROVIDER DEMONSTRATION: Local Provider Resources

# 1. local_file - Creates and manages regular files
resource "local_file" "app_config" {
  filename = "${path.module}/output/app-config.json"
  content = jsonencode(local.app_config)
  
  # File permissions (on Unix systems)
  file_permission = "0644"
  
  # Directory permissions (on Unix systems)  
  directory_permission = "0755"
}

# 2. local_file with direct template content
resource "local_file" "docker_compose" {
  filename = "${path.module}/output/docker-compose.yml"
  content = <<-EOT
    # Docker Compose for ${var.project_name}
    # Environment: ${var.environment}
    
    version: '3.8'
    
    services:
      app:
        build: .
        ports:
          - "8080:8080"
        environment:
          - NODE_ENV=${var.environment}
          - PROJECT_NAME=${var.project_name}
        depends_on:
          - database
          - redis
      
      database:
        image: postgres:14
        ports:
          - "5432:5432"
        environment:
          - POSTGRES_DB=${var.project_name}
          - POSTGRES_USER=app_user
          - POSTGRES_PASSWORD=app_password
        volumes:
          - postgres_data:/var/lib/postgresql/data
      
      redis:
        image: redis:7-alpine
        ports:
          - "6379:6379"
        volumes:
          - redis_data:/data
    
    volumes:
      postgres_data:
      redis_data:
    
    networks:
      default:
        name: ${var.project_name}-${var.environment}
  EOT
}

# 3. local_file for each team member
resource "local_file" "team_member_configs" {
  for_each = {
    for member in local.team_members : member.name => member
  }
  
  filename = "${path.module}/output/team/${each.value.name}.yaml"
  content = yamlencode({
    member = {
      id    = each.value.id
      name  = each.value.name
      email = each.value.email
      role  = each.value.role
    }
    project = {
      name        = var.project_name
      environment = var.environment
    }
    permissions = {
      read_logs    = true
      deploy       = each.value.role == "lead"
      admin_access = each.value.role == "lead"
    }
  })
}

# 4. local_sensitive_file - For sensitive data
resource "local_sensitive_file" "secrets" {
  count = var.create_sensitive_files ? 1 : 0
  
  filename = "${path.module}/output/.secrets.env"
  content = <<-EOT
    # Sensitive environment variables
    DATABASE_PASSWORD=super-secret-password-123
    API_KEY=sk-1234567890abcdef
    JWT_SECRET=jwt-signing-secret-key
    ENCRYPTION_KEY=encryption-key-32-bytes-long
    
    # Project information
    PROJECT=${var.project_name}
    ENVIRONMENT=${var.environment}
    CREATED_AT=${local.timestamp}
  EOT
  
  # This file will have restricted permissions (0600 on Unix)
  file_permission = "0600"
}

# 5. Multiple files with count
resource "local_file" "environment_configs" {
  count = 3
  
  filename = "${path.module}/output/environments/env-${count.index + 1}.conf"
  content = <<-EOT
    # Environment Configuration ${count.index + 1}
    ENV_ID=${count.index + 1}
    ENV_NAME=${var.environment}-${count.index + 1}
    PROJECT=${var.project_name}
    
    [database]
    host=db-${count.index + 1}.${var.environment}.local
    port=5432
    database=${var.project_name}_${count.index + 1}
    
    [redis]
    host=redis-${count.index + 1}.${var.environment}.local
    port=6379
    
    [application]
    port=${8080 + count.index}
    workers=${2 + count.index}
    debug=${var.environment == "development"}
  EOT
}

# 6. Create README with provider information
resource "local_file" "provider_readme" {
  filename = "${path.module}/output/PROVIDER_INFO.md"
  content = <<-EOT
    # Local Provider Demonstration
    
    ## What is a Terraform Provider?
    
    A provider in Terraform is a plugin that defines resource types and data sources 
    for a particular platform or service. The local provider manages local files 
    and directories on the machine running Terraform.
    
    ## Local Provider Resources Used:
    
    ### 1. local_file
    - Creates and manages regular files
    - Can set file and directory permissions
    - Supports template rendering
    - Example: Configuration files, scripts, documentation
    
    ### 2. local_sensitive_file  
    - Similar to local_file but for sensitive data
    - Content is marked as sensitive in Terraform state
    - Automatically sets restrictive permissions (0600)
    - Example: API keys, passwords, certificates
    
    ## Provider Configuration
    
    ```hcl
    terraform {
      required_providers {
        local = {
          source  = "hashicorp/local"
          version = "~> 2.4"
        }
      }
    }
    ```
    
    ## Files Created in This Demo:
    
    - app-config.json (Application configuration)
    - docker-compose.yml (Docker Compose file)
    - team/*.yaml (Team member configurations)
    - .secrets.env (Sensitive environment variables)
    - environments/*.conf (Environment-specific configs)
    - PROVIDER_INFO.md (This file)
    
    ## Provider Benefits:
    
    1. **Consistency**: Files are managed as code
    2. **Versioning**: Changes are tracked in version control
    3. **Automation**: Files created/updated automatically
    4. **Integration**: Works with other Terraform resources
    5. **State Management**: Terraform tracks file state
    
    ## Real-World Use Cases:
    
    - Configuration file generation
    - Script creation for deployment
    - Documentation generation
    - Secret management (with care)
    - Integration with other tools
    
    ## Project: ${var.project_name}
    ## Environment: ${var.environment}
    ## Created: ${local.timestamp}
    ## Team Size: ${var.team_size}
  EOT
}

# 7. Create template file for docker-compose
resource "local_file" "docker_compose_template" {
  filename = "${path.module}/templates/docker-compose.yml.tpl"
  content = <<-EOT
    # Docker Compose for $${project_name}
    # Environment: $${environment}
    
    version: '3.8'
    
    services:
      app:
        build: .
        ports:
          - "$${app_port}:8080"
        environment:
          - NODE_ENV=$${environment}
          - PROJECT_NAME=$${project_name}
        depends_on:
          - database
          - redis
      
      database:
        image: postgres:14
        ports:
          - "$${db_port}:5432"
        environment:
          - POSTGRES_DB=$${project_name}
          - POSTGRES_USER=app_user
          - POSTGRES_PASSWORD=app_password
        volumes:
          - postgres_data:/var/lib/postgresql/data
      
      redis:
        image: redis:7-alpine
        ports:
          - "6379:6379"
        volumes:
          - redis_data:/data
    
    volumes:
      postgres_data:
      redis_data:
    
    networks:
      default:
        name: $${project_name}-$${environment}
  EOT
}

# Data source to read the created app config
data "local_file" "read_app_config" {
  filename = local_file.app_config.filename
}

# Outputs demonstrating provider capabilities
output "provider_summary" {
  description = "Summary of what the local provider created"
  value = {
    provider_name = "local"
    provider_version = "~> 2.4"
    
    files_created = {
      app_config        = local_file.app_config.filename
      docker_compose    = local_file.docker_compose.filename
      team_configs      = length(local_file.team_member_configs)
      env_configs       = length(local_file.environment_configs)
      sensitive_files   = var.create_sensitive_files ? 1 : 0
      documentation     = local_file.provider_readme.filename
    }
    
    total_files = (
      1 +  # app_config
      1 +  # docker_compose  
      length(local_file.team_member_configs) +
      length(local_file.environment_configs) +
      (var.create_sensitive_files ? 1 : 0) +
      2    # readme + template
    )
  }
}

output "app_configuration" {
  description = "Application configuration read from file"
  value = jsondecode(data.local_file.read_app_config.content)
}

output "team_structure" {
  description = "Team structure and file locations"
  value = {
    team_size = var.team_size
    team_lead = [for member in local.team_members : member.name if member.role == "lead"][0]
    
    team_files = {
      for name, config in local_file.team_member_configs : name => config.filename
    }
    
    environment_files = [
      for config in local_file.environment_configs : config.filename
    ]
  }
}

output "sensitive_file_info" {
  description = "Information about sensitive files (content hidden)"
  sensitive = true
  value = var.create_sensitive_files ? {
    file_created = true
    file_path    = local_sensitive_file.secrets[0].filename
    file_size    = length(local_sensitive_file.secrets[0].content)
    note         = "Content is hidden because it's marked as sensitive"
  } : {
    file_created = false
    note         = "Sensitive files were not created (create_sensitive_files = false)"
  }
}

output "provider_learning_notes" {
  description = "Key learning points about Terraform providers"
  value = <<-EOT
    
    TERRAFORM PROVIDER CONCEPTS:
    
    1. WHAT IS A PROVIDER?
       - A plugin that implements resource types
       - Translates Terraform config to API calls
       - Manages the lifecycle of resources
    
    2. LOCAL PROVIDER SPECIFICALLY:
       - Manages files and directories
       - Useful for configuration generation
       - Good for learning Terraform concepts
       - No external dependencies required
    
    3. PROVIDER CONFIGURATION:
       - Defined in required_providers block
       - Version constraints ensure compatibility
       - Source specifies where to download from
    
    4. RESOURCE TYPES IN LOCAL PROVIDER:
       - local_file: Regular files with content
       - local_sensitive_file: Files with sensitive content
       
    5. KEY FEATURES DEMONSTRATED:
       - File creation and management
       - Content templating
       - Permission management
       - Sensitive data handling
       - Multiple file creation patterns
    
    Files created: ${1 + 1 + length(local_file.team_member_configs) + length(local_file.environment_configs) + (var.create_sensitive_files ? 1 : 0) + 2}
    
  EOT
}