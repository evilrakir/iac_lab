# Exercise: Creating and Using Terraform Modules
# Learn how to build reusable infrastructure components

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

# ========================================================================
# SECTION 1: USING A LOCAL MODULE
# ========================================================================

# Call our module with minimal configuration
module "web_app" {
  source = "./my-first-module"  # Path to local module
  
  # Required variables (no defaults in module)
  app_name    = "web-frontend"
  environment = "dev"
  
  # Optional variables (using defaults)
  # app_version = "1.0.0"  # Using default
  # port = 8080            # Using default
}

# Call the same module with different configuration
module "api_service" {
  source = "./my-first-module"
  
  # Required variables
  app_name    = "api-backend"
  environment = "staging"
  
  # Override optional variables
  app_version = "2.1.0"
  port        = 3000
  
  features = {
    monitoring = true
    logging    = true
    caching    = true   # Enabled for API
    debug      = false
  }
  
  database_enabled = true
  database_type    = "postgresql"
  
  tags = {
    managed_by = "terraform"
    team       = "backend"
    cost_center = "engineering"
  }
}

# Another instance with production settings
module "production_app" {
  source = "./my-first-module"
  
  app_name    = "main-application"
  environment = "prod"
  app_version = "3.0.0"
  port        = 443
  
  features = {
    monitoring = true
    logging    = true
    caching    = true
    debug      = false  # Never in production!
  }
  
  database_enabled = true
  database_type    = "postgresql"
  create_readme    = false  # Don't need README in prod
  
  output_path = "${path.module}/production-configs"
  
  tags = {
    managed_by  = "terraform"
    environment = "production"
    criticality = "high"
    owner       = "platform-team"
  }
}

# ========================================================================
# SECTION 2: MODULE COMPOSITION (modules using modules)
# ========================================================================

# Create a "super module" that uses our basic module multiple times
module "microservices_stack" {
  source = "./my-first-module"
  
  app_name    = "microservices"
  environment = "dev"
  app_version = "1.0.0"
  
  # This could represent a gateway that connects to other services
  features = {
    monitoring = true
    logging    = true
    caching    = true
    debug      = true
  }
  
  output_path = "${path.module}/microservices"
}

# ========================================================================
# SECTION 3: USING MODULE OUTPUTS
# ========================================================================

# Create a file using outputs from modules
resource "local_file" "deployment_manifest" {
  filename = "${path.module}/DEPLOYMENT_MANIFEST.json"
  
  content = jsonencode({
    deployments = {
      web_app = {
        identifier = module.web_app.app_identifier
        port       = module.web_app.port
        features   = module.web_app.enabled_features
        files      = module.web_app.all_file_paths
      }
      
      api_service = {
        identifier = module.api_service.app_identifier
        port       = module.api_service.port
        features   = module.api_service.enabled_features
        database   = module.api_service.database_config
        files      = module.api_service.all_file_paths
      }
      
      production = {
        identifier = module.production_app.app_identifier
        port       = module.production_app.port
        features   = module.production_app.enabled_features
        database   = module.production_app.database_config
        files      = module.production_app.all_file_paths
      }
    }
    
    summary = {
      total_apps = 4
      environments = ["dev", "staging", "prod"]
      databases_enabled = 2
      timestamp = timestamp()
    }
  })
}

# ========================================================================
# SECTION 4: CONDITIONAL MODULE USAGE
# ========================================================================

variable "deploy_monitoring" {
  description = "Whether to deploy monitoring"
  type        = bool
  default     = true
}

# Conditionally create module instances using count
module "monitoring_service" {
  count  = var.deploy_monitoring ? 1 : 0
  source = "./my-first-module"
  
  app_name    = "monitoring"
  environment = "dev"
  app_version = "1.0.0"
  port        = 9090
  
  features = {
    monitoring = false  # Monitoring doesn't monitor itself
    logging    = true
    caching    = false
    debug      = true
  }
}

# ========================================================================
# SECTION 5: DYNAMIC MODULE CONFIGURATION
# ========================================================================

variable "services" {
  description = "Map of services to deploy"
  type = map(object({
    version  = string
    port     = number
    database = bool
  }))
  default = {
    auth = {
      version  = "1.0.0"
      port     = 8081
      database = true
    }
    payment = {
      version  = "1.1.0"
      port     = 8082
      database = true
    }
    notification = {
      version  = "2.0.0"
      port     = 8083
      database = false
    }
  }
}

# Create module instances dynamically from a map
module "dynamic_services" {
  for_each = var.services
  source   = "./my-first-module"
  
  app_name    = each.key
  environment = "dev"
  app_version = each.value.version
  port        = each.value.port
  
  database_enabled = each.value.database
  
  output_path = "${path.module}/services/${each.key}"
}

# ========================================================================
# SECTION 6: MODULE BEST PRACTICES DEMONSTRATION
# ========================================================================

# Create a summary showing module best practices
resource "local_file" "module_best_practices" {
  filename = "${path.module}/MODULE_BEST_PRACTICES.md"
  
  content = <<-EOT
    # Terraform Module Best Practices
    
    ## Module Structure
    - **main.tf**: Core resource definitions
    - **variables.tf**: Input variable definitions
    - **outputs.tf**: Output value definitions
    - **README.md**: Module documentation
    
    ## Variable Guidelines
    1. Required variables have no defaults
    2. Optional variables have sensible defaults
    3. Use validation blocks for input validation
    4. Use descriptive variable names
    
    ## Output Guidelines
    1. Output commonly needed values
    2. Group related outputs
    3. Mark sensitive outputs appropriately
    4. Provide descriptive output names
    
    ## Module Usage Patterns Demonstrated
    
    ### 1. Basic Module Usage
    - Module: web_app
    - Shows: Minimal configuration with defaults
    
    ### 2. Full Configuration
    - Module: api_service
    - Shows: Overriding all optional variables
    
    ### 3. Production Configuration
    - Module: production_app
    - Shows: Production-ready settings
    
    ### 4. Conditional Modules
    - Module: monitoring_service
    - Shows: Using count for conditional creation
    
    ### 5. Dynamic Modules
    - Module: dynamic_services
    - Shows: Using for_each for multiple instances
    
    ## PowerShell Analogy
    Terraform modules are like PowerShell functions:
    - Variables = Function parameters
    - Outputs = Return values
    - Module source = Dot-sourcing a script
    - Module instance = Function call
    
    ## Module Versioning
    - Local modules: Use relative paths
    - Registry modules: Use version constraints
    - Git modules: Use tags or branches
    
    ## Module Testing
    1. Test with minimal configuration
    2. Test with full configuration
    3. Test with edge cases
    4. Validate all outputs
    
    Generated at: ${timestamp()}
  EOT
}

# ========================================================================
# OUTPUTS - Demonstrate using module outputs
# ========================================================================

output "all_applications" {
  description = "Summary of all deployed applications"
  value = {
    web_app     = module.web_app.configuration_summary
    api_service = module.api_service.configuration_summary
    production  = module.production_app.configuration_summary
    microservices = module.microservices_stack.configuration_summary
    
    # Include monitoring if deployed
    monitoring = var.deploy_monitoring ? module.monitoring_service[0].configuration_summary : null
    
    # Include dynamic services
    dynamic_services = {
      for name, service in module.dynamic_services : 
      name => service.configuration_summary
    }
  }
}

output "database_connections" {
  description = "All database connection strings"
  value = {
    api_service = module.api_service.database_connection_string
    production  = module.production_app.database_connection_string
    
    dynamic_services = {
      for name, service in module.dynamic_services :
      name => service.database_connection_string
      if service.database_enabled
    }
  }
  sensitive = true
}

output "port_mapping" {
  description = "Port assignments for all services"
  value = merge(
    {
      web_app       = module.web_app.port
      api_service   = module.api_service.port
      production    = module.production_app.port
      microservices = module.microservices_stack.port
    },
    {
      for name, service in module.dynamic_services :
      name => service.port
    }
  )
}

output "module_learning_summary" {
  description = "What you learned about modules"
  value = <<-EOT
    
    MODULE CONCEPTS DEMONSTRATED:
    
    1. Module Structure:
       - Encapsulated resources
       - Input variables
       - Output values
       
    2. Module Usage:
       - Local modules with relative paths
       - Multiple instances of same module
       - Different configurations per instance
       
    3. Module Patterns:
       - Conditional modules (count)
       - Dynamic modules (for_each)
       - Module composition
       
    4. Module Outputs:
       - Accessing module outputs
       - Chaining modules
       - Aggregating module data
       
    5. Best Practices:
       - Clear variable definitions
       - Sensible defaults
       - Comprehensive outputs
       - Input validation
       
    Modules created: ${4 + (var.deploy_monitoring ? 1 : 0) + length(var.services)}
    Files generated: ${3 * 4 + (var.deploy_monitoring ? 3 : 0) + length(var.services) * 3}
    
  EOT
}