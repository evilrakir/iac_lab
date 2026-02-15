# ╔════════════════════════════════════════════════════════════════════╗
# ║  MODULE INPUT VARIABLES - PARAMETERIZING MODULES                 ║
# ║  Learn how to pass data into reusable modules                    ║
# ╚════════════════════════════════════════════════════════════════════╝

# In the previous exercise, you created a module and called it with
# hardcoded values. Now we'll learn how to make modules truly flexible
# by using different variable types, defaults, and validation.

# POWERSHELL COMPARISON:
# =====================
# Modules with variables are like PowerShell functions with parameters:
#   function Deploy-App {
#     param(
#       [Parameter(Mandatory)]
#       [string]$AppName,
#       [ValidateSet('dev','staging','prod')]
#       [string]$Environment = 'dev'
#     )
#   }

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
# THE MODULE: A reusable "app deployer" with rich variable interface
# ========================================================================
# We define a local module (in ./app-module/) that accepts many variable
# types. Then we call it multiple ways below to show the flexibility.

# ========================================================================
# SECTION 1: CALLING MODULE WITH REQUIRED VARIABLES ONLY
# ========================================================================

module "minimal_app" {
  source = "./app-module"

  # Only the required variables - everything else uses defaults
  app_name = "minimal-service"
}

# POWERSHELL EQUIVALENT:
# Deploy-App -AppName "minimal-service"
# All other parameters use their defaults

# ========================================================================
# SECTION 2: CALLING MODULE WITH ALL VARIABLE TYPES
# ========================================================================

module "full_app" {
  source = "./app-module"

  # String variable (required)
  app_name = "full-service"

  # String with validation (like [ValidateSet()])
  environment = "staging"

  # Number variable (like [int])
  replicas = 3

  # Boolean variable (like [switch] or [bool])
  enable_logging = true

  # List variable (like [string[]])
  allowed_origins = ["https://example.com", "https://app.example.com", "http://localhost:3000"]

  # Map variable (like [hashtable])
  tags = {
    team        = "backend"
    cost_center = "engineering"
    owner       = "platform-team"
  }

  # Object variable (like [PSCustomObject])
  database_config = {
    engine         = "postgresql"
    version        = "15"
    storage_gb     = 100
    backup_enabled = true
  }

  # Tuple variable (fixed-length typed list)
  port_range = [8080, 8090]
}

# ========================================================================
# SECTION 3: SAME MODULE, DIFFERENT ENVIRONMENTS
# ========================================================================

# This demonstrates the power of modules - same code, different inputs!
module "dev_app" {
  source         = "./app-module"
  app_name       = "my-app"
  environment    = "development"
  replicas       = 1
  enable_logging = true
  tags           = { team = "dev" }
}

module "prod_app" {
  source         = "./app-module"
  app_name       = "my-app"
  environment    = "production"
  replicas       = 5
  enable_logging = true
  allowed_origins = ["https://myapp.com"]
  database_config = {
    engine         = "postgresql"
    version        = "15"
    storage_gb     = 500
    backup_enabled = true
  }
  tags = { team = "platform", criticality = "high" }
}

# ========================================================================
# SECTION 4: USING MODULE FOR_EACH (Advanced Pattern)
# ========================================================================

# Create multiple module instances from a map - like ForEach-Object
variable "microservices" {
  description = "Map of microservices to deploy"
  type = map(object({
    replicas    = number
    environment = string
  }))
  default = {
    auth = { replicas = 2, environment = "development" }
    api  = { replicas = 3, environment = "development" }
    web  = { replicas = 2, environment = "development" }
  }
}

module "services" {
  source   = "./app-module"
  for_each = var.microservices

  app_name    = each.key
  environment = each.value.environment
  replicas    = each.value.replicas
  tags        = { service = each.key }
}

# ========================================================================
# SECTION 5: POWERSHELL COMPARISON SCRIPT
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-module-variables.ps1"
  content  = <<-EOT
    # PowerShell vs Terraform: Module Variables Comparison
    # ====================================================

    # TERRAFORM variable types map to PowerShell parameter types:
    #
    # Terraform          | PowerShell
    # -------------------|------------------
    # string             | [string]
    # number             | [int] or [double]
    # bool               | [bool] or [switch]
    # list(string)       | [string[]]
    # map(string)        | [hashtable]
    # object({...})      | [PSCustomObject]
    # tuple([...])       | Fixed-type array

    function Deploy-Application {
        param(
            [Parameter(Mandatory)]
            [ValidateLength(2,50)]
            [string]$AppName,

            [ValidateSet('development', 'staging', 'production')]
            [string]$Environment = 'development',

            [ValidateRange(1, 10)]
            [int]$Replicas = 1,

            [bool]$EnableLogging = $$false,

            [string[]]$AllowedOrigins = @(),

            [hashtable]$Tags = @{}
        )

        Write-Host "Deploying $$AppName to $$Environment with $$Replicas replicas"
        Write-Host "Logging: $$EnableLogging"
        Write-Host "Origins: $$($AllowedOrigins -join ', ')"
    }

    # Minimal call (like module.minimal_app)
    Deploy-Application -AppName "minimal-service"

    # Full call (like module.full_app)
    Deploy-Application `
        -AppName "full-service" `
        -Environment "staging" `
        -Replicas 3 `
        -EnableLogging $$true `
        -AllowedOrigins @("https://example.com") `
        -Tags @{ team = "backend"; owner = "platform" }
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "minimal_app_summary" {
  description = "Output from minimal module call"
  value       = module.minimal_app.app_summary
}

output "full_app_summary" {
  description = "Output from fully-configured module call"
  value       = module.full_app.app_summary
}

output "environment_comparison" {
  description = "Dev vs Prod configuration comparison"
  value = {
    dev  = module.dev_app.app_summary
    prod = module.prod_app.app_summary
  }
}

output "microservices_deployed" {
  description = "All microservices deployed via for_each"
  value       = { for k, v in module.services : k => v.app_summary }
}
