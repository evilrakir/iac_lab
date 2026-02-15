# ╔════════════════════════════════════════════════════════════════════╗
# ║  TERRAFORM WORKSPACES                                            ║
# ║  Manage multiple environments with the same configuration       ║
# ╚════════════════════════════════════════════════════════════════════╝

# Workspaces allow you to use the same Terraform configuration for
# multiple environments (dev, staging, prod) with separate state files.
# This exercise creates workspace-aware configurations using locals.

# POWERSHELL COMPARISON:
# =====================
# Like PowerShell parameter sets or environment profiles:
#   $env:ENVIRONMENT = "production"
#   ./Deploy-Infrastructure.ps1 -Environment Production
# Workspaces are: terraform workspace select production

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
# VARIABLES
# ========================================================================

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "webapp"
}

variable "base_domain" {
  description = "Base domain for the project"
  type        = string
  default     = "example.com"
}

# ========================================================================
# SECTION 1: WORKSPACE-AWARE CONFIGURATION
# ========================================================================

# The terraform.workspace variable contains the current workspace name.
# Use it to vary configuration per environment.

locals {
  # Current workspace name (default, development, staging, production)
  environment = terraform.workspace

  # Environment-specific settings
  env_config = {
    default = {
      instance_type = "t3.micro"
      replicas      = 1
      domain        = "dev.${var.base_domain}"
      enable_debug  = true
      db_size       = "db.t3.micro"
      min_nodes     = 1
      max_nodes     = 2
    }
    development = {
      instance_type = "t3.small"
      replicas      = 1
      domain        = "dev.${var.base_domain}"
      enable_debug  = true
      db_size       = "db.t3.small"
      min_nodes     = 1
      max_nodes     = 3
    }
    staging = {
      instance_type = "t3.medium"
      replicas      = 2
      domain        = "staging.${var.base_domain}"
      enable_debug  = false
      db_size       = "db.t3.medium"
      min_nodes     = 2
      max_nodes     = 5
    }
    production = {
      instance_type = "t3.large"
      replicas      = 3
      domain        = "${var.base_domain}"
      enable_debug  = false
      db_size       = "db.r5.large"
      min_nodes     = 3
      max_nodes     = 10
    }
  }

  # Look up current workspace config (fall back to default)
  current = lookup(local.env_config, local.environment, local.env_config["default"])

  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
    Workspace   = terraform.workspace
  }
}

# Generate environment-specific configuration
resource "local_file" "env_config" {
  filename = "./terraform-lab-output/workspaces/${local.environment}-config.json"
  content = jsonencode({
    environment   = local.environment
    workspace     = terraform.workspace
    instance_type = local.current.instance_type
    replicas      = local.current.replicas
    domain        = local.current.domain
    debug_enabled = local.current.enable_debug
    database_size = local.current.db_size
    autoscaling = {
      min_nodes = local.current.min_nodes
      max_nodes = local.current.max_nodes
    }
    tags = local.common_tags
  })
}

# ========================================================================
# SECTION 2: WORKSPACE COMMANDS REFERENCE
# ========================================================================

resource "local_file" "workspace_commands" {
  filename = "./terraform-lab-output/workspaces/workspace-commands.md"
  content  = <<-EOT
    # Terraform Workspace Commands

    ## Basic Commands
    ```bash
    # List all workspaces (* marks current)
    terraform workspace list

    # Create a new workspace
    terraform workspace new development
    terraform workspace new staging
    terraform workspace new production

    # Switch to a workspace
    terraform workspace select staging

    # Show current workspace
    terraform workspace show

    # Delete a workspace (must switch away first)
    terraform workspace select default
    terraform workspace delete staging
    ```

    ## Current Workspace: ${local.environment}
    - Instance Type: ${local.current.instance_type}
    - Replicas: ${local.current.replicas}
    - Domain: ${local.current.domain}
    - Debug: ${local.current.enable_debug}

    ## How State is Organized
    ```
    .terraform/
    └── terraform.tfstate.d/
        ├── development/
        │   └── terraform.tfstate
        ├── staging/
        │   └── terraform.tfstate
        └── production/
            └── terraform.tfstate
    ```

    With remote backends (S3):
    ```
    s3://my-bucket/
    └── env:/
        ├── development/
        │   └── terraform.tfstate
        ├── staging/
        │   └── terraform.tfstate
        └── production/
            └── terraform.tfstate
    ```

    ## Workspace Workflow
    ```bash
    # Deploy to development
    terraform workspace select development
    terraform apply

    # Deploy to staging
    terraform workspace select staging
    terraform apply

    # Deploy to production (with extra safety)
    terraform workspace select production
    terraform plan -out=prod.tfplan
    # Review the plan carefully!
    terraform apply prod.tfplan
    ```
  EOT
}

# ========================================================================
# SECTION 3: WORKSPACE vs DIRECTORY STRUCTURE
# ========================================================================

resource "local_file" "workspace_vs_dirs" {
  filename = "./terraform-lab-output/workspaces/workspaces-vs-directories.json"
  content = jsonencode({
    title      = "Workspaces vs Directory-Based Environments"
    comparison = {
      workspaces = {
        approach    = "One config, multiple workspaces"
        structure   = "project/ (single directory)"
        switch      = "terraform workspace select <env>"
        state       = "Separate state per workspace"
        pros = [
          "DRY - no code duplication",
          "Easy to keep environments in sync",
          "Built-in Terraform feature"
        ]
        cons = [
          "All environments share same config (can be limiting)",
          "Easy to accidentally apply to wrong workspace",
          "Hard to have different resources per environment"
        ]
        best_for = "Similar environments that differ only in size/scale"
      }
      directories = {
        approach    = "Separate directory per environment"
        structure   = "environments/dev/, environments/staging/, environments/prod/"
        switch      = "cd environments/production && terraform apply"
        state       = "Separate state per directory"
        pros = [
          "Full control per environment",
          "Clear separation - hard to mix up",
          "Can have different resources per environment",
          "Easier code review per environment"
        ]
        cons = [
          "Code duplication across directories",
          "Must update each environment separately",
          "More files to maintain"
        ]
        best_for = "Environments that differ significantly in structure"
      }
    }
    recommendation = "Use workspaces for simple scaling, directories for complex differences"
  })
}

# ========================================================================
# SECTION 4: WORKSPACE-AWARE RESOURCE NAMING
# ========================================================================

resource "local_file" "naming_patterns" {
  filename = "./terraform-lab-output/workspaces/${local.environment}-resources.tf"
  content  = <<-EOT
    # ============================================
    # WORKSPACE-AWARE RESOURCE NAMING
    # ============================================
    # Resources include the workspace/environment in their names
    # to prevent collisions between environments.

    # Current workspace: ${local.environment}

    # Example: EC2 Instance
    # resource "aws_instance" "app" {
    #   ami           = "ami-12345678"
    #   instance_type = "${local.current.instance_type}"
    #   tags = {
    #     Name = "${var.project_name}-$${terraform.workspace}-app"
    #   }
    # }

    # Example: S3 Bucket (globally unique names!)
    # resource "aws_s3_bucket" "assets" {
    #   bucket = "${var.project_name}-$${terraform.workspace}-assets"
    # }

    # Example: Database
    # resource "aws_db_instance" "main" {
    #   identifier     = "${var.project_name}-$${terraform.workspace}-db"
    #   instance_class = "${local.current.db_size}"
    # }

    # Example: DNS Record
    # resource "aws_route53_record" "app" {
    #   name = "${local.current.domain}"
    #   type = "A"
    #   # ...
    # }

    # Safety: Prevent destroy in production
    # lifecycle {
    #   prevent_destroy = terraform.workspace == "production" ? true : false
    # }
    # Note: prevent_destroy must be a literal, not expression.
    # Use a variable or separate config for this pattern.
  EOT
}

# ========================================================================
# SECTION 5: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-workspaces.ps1"
  content  = <<-EOT
    # Workspaces: Terraform vs PowerShell Environment Patterns
    # =========================================================

    # TERRAFORM WORKSPACES           | POWERSHELL EQUIVALENT
    # -------------------------------|-------------------------------
    # terraform workspace new dev    | $$env:ENVIRONMENT = "dev"
    # terraform workspace select prod| $$env:ENVIRONMENT = "prod"
    # terraform.workspace variable   | $$env:ENVIRONMENT variable
    # Separate state per workspace   | Separate config files per env

    # PowerShell: Environment-based configuration
    # ---------------------------------------------

    param(
        [ValidateSet("development", "staging", "production")]
        [string]$$Environment = "development"
    )

    # Environment-specific settings (like Terraform locals)
    $$envConfig = @{
        development = @{
            InstanceType = "t3.small"
            Replicas     = 1
            Domain       = "dev.example.com"
            Debug        = $$true
        }
        staging = @{
            InstanceType = "t3.medium"
            Replicas     = 2
            Domain       = "staging.example.com"
            Debug        = $$false
        }
        production = @{
            InstanceType = "t3.large"
            Replicas     = 3
            Domain       = "example.com"
            Debug        = $$false
        }
    }

    $$config = $$envConfig[$$Environment]
    Write-Host "Deploying to: $$Environment" -ForegroundColor Yellow
    Write-Host "  Instance Type: $$($config.InstanceType)"
    Write-Host "  Replicas: $$($config.Replicas)"
    Write-Host "  Domain: $$($config.Domain)"

    # PowerShell parameter sets vs Terraform workspaces:
    # - Both let you reuse code across environments
    # - Terraform tracks state separately per workspace
    # - PowerShell has no built-in state tracking
    # - Terraform prevents accidental cross-env operations

    Write-Host "`nKey Insight:" -ForegroundColor Yellow
    Write-Host "  Terraform workspaces = isolated state per environment"
    Write-Host "  PowerShell params = same script, different inputs (no state isolation)"
    Write-Host "  Both solve the 'one config, multiple environments' problem"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "current_workspace" {
  description = "Current workspace information"
  value = {
    name        = terraform.workspace
    environment = local.environment
    config      = local.current
    tags        = local.common_tags
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    concept         = "Workspaces provide separate state for each environment"
    usage           = "terraform workspace new/select/list/delete"
    variable        = "terraform.workspace contains the current workspace name"
    state_isolation = "Each workspace has its own terraform.tfstate"
    naming          = "Include workspace name in resource names to prevent collisions"
    alternative     = "Directory-based separation for complex environment differences"
  }
}
