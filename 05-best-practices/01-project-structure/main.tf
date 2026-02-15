# ╔════════════════════════════════════════════════════════════════════╗
# ║  PROJECT STRUCTURE AND ORGANIZATION                              ║
# ║  Organize Terraform projects for teams and production           ║
# ╚════════════════════════════════════════════════════════════════════╝

# A well-organized Terraform project is easier to maintain, review,
# and collaborate on. This exercise demonstrates standard patterns
# for file organization, environment separation, and team workflows.

# POWERSHELL COMPARISON:
# =====================
# Like organizing a PowerShell module with proper structure:
#   MyModule/
#     MyModule.psd1 (manifest) -> versions.tf (provider constraints)
#     MyModule.psm1 (code)     -> main.tf (resources)
#     Public/ (exported)       -> outputs.tf (public interface)
#     Private/ (internal)      -> locals (internal logic)

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
# SECTION 1: STANDARD FILE LAYOUT
# ========================================================================

resource "local_file" "file_layout" {
  filename = "./terraform-lab-output/project-structure/standard-layout.md"
  content  = <<-EOT
    # Standard Terraform Project File Layout

    ## Minimal Project (1-2 people)
    ```
    project/
    ├── main.tf              # Resource definitions
    ├── variables.tf         # Input variable declarations
    ├── outputs.tf           # Output value declarations
    ├── versions.tf          # Provider and Terraform version constraints
    ├── terraform.tfvars     # Variable values (don't commit secrets!)
    └── .gitignore           # Ignore state, plans, .terraform/
    ```

    ## Standard Project (small team)
    ```
    project/
    ├── main.tf              # Primary resources and data sources
    ├── variables.tf         # All variable declarations
    ├── outputs.tf           # All output declarations
    ├── versions.tf          # Provider requirements
    ├── locals.tf            # Local values (computed variables)
    ├── data.tf              # Data source declarations
    ├── providers.tf         # Provider configuration blocks
    ├── terraform.tfvars     # Default variable values
    ├── modules/             # Local reusable modules
    │   ├── networking/
    │   └── compute/
    └── .gitignore
    ```

    ## Enterprise Project (multiple teams)
    ```
    infrastructure/
    ├── modules/                    # Shared reusable modules
    │   ├── vpc/
    │   ├── ecs-cluster/
    │   └── rds-database/
    ├── environments/               # Per-environment configs
    │   ├── dev/
    │   │   ├── main.tf
    │   │   ├── terraform.tfvars
    │   │   └── backend.tf
    │   ├── staging/
    │   │   ├── main.tf
    │   │   ├── terraform.tfvars
    │   │   └── backend.tf
    │   └── production/
    │       ├── main.tf
    │       ├── terraform.tfvars
    │       └── backend.tf
    ├── global/                     # Shared across all environments
    │   ├── iam/
    │   ├── dns/
    │   └── s3-buckets/
    └── README.md
    ```

    ## File Purpose Reference
    | File | Purpose | Required? |
    |------|---------|-----------|
    | main.tf | Primary resources | Yes |
    | variables.tf | Input declarations | Yes |
    | outputs.tf | Output declarations | Yes |
    | versions.tf | Version constraints | Recommended |
    | locals.tf | Computed values | Optional |
    | data.tf | Data sources | Optional |
    | providers.tf | Provider config | Optional (can be in main.tf) |
    | terraform.tfvars | Variable values | Optional |
    | backend.tf | State backend config | Production |
  EOT
}

# ========================================================================
# SECTION 2: GENERATE EXAMPLE PROJECT STRUCTURE
# ========================================================================

# Generate a complete example project with all standard files
resource "local_file" "example_main" {
  filename = "./terraform-lab-output/project-structure/example-project/main.tf"
  content  = <<-EOT
    # Main resources for the web application

    module "vpc" {
      source = "../../modules/vpc"
      name   = "$${var.project_name}-$${var.environment}"
      cidr   = var.vpc_cidr
    }

    module "web_server" {
      source        = "../../modules/compute"
      name          = "$${var.project_name}-web"
      instance_type = var.instance_type
      subnet_id     = module.vpc.public_subnet_ids[0]
    }
  EOT
}

resource "local_file" "example_variables" {
  filename = "./terraform-lab-output/project-structure/example-project/variables.tf"
  content  = <<-EOT
    # All input variables in one place for easy reference

    variable "project_name" {
      description = "Name of the project"
      type        = string
    }

    variable "environment" {
      description = "Deployment environment (dev, staging, prod)"
      type        = string
      validation {
        condition     = contains(["dev", "staging", "prod"], var.environment)
        error_message = "Environment must be dev, staging, or prod."
      }
    }

    variable "vpc_cidr" {
      description = "CIDR block for the VPC"
      type        = string
      default     = "10.0.0.0/16"
    }

    variable "instance_type" {
      description = "EC2 instance type"
      type        = string
      default     = "t3.medium"
    }
  EOT
}

resource "local_file" "example_outputs" {
  filename = "./terraform-lab-output/project-structure/example-project/outputs.tf"
  content  = <<-EOT
    # Outputs exposed by this project

    output "vpc_id" {
      description = "ID of the VPC"
      value       = module.vpc.vpc_id
    }

    output "web_server_ip" {
      description = "Public IP of the web server"
      value       = module.web_server.public_ip
    }

    output "web_url" {
      description = "URL to access the web application"
      value       = "https://$${module.web_server.public_ip}"
    }
  EOT
}

resource "local_file" "example_versions" {
  filename = "./terraform-lab-output/project-structure/example-project/versions.tf"
  content  = <<-EOT
    # Pin provider and Terraform versions for reproducibility

    terraform {
      required_version = ">= 1.5.0, < 2.0.0"

      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 5.0"
        }
      }
    }
  EOT
}

resource "local_file" "example_gitignore" {
  filename = "./terraform-lab-output/project-structure/example-project/.gitignore-example"
  content  = <<-EOT
    # Terraform state (contains secrets!)
    *.tfstate
    *.tfstate.*

    # Terraform working directory
    .terraform/

    # Plan files (may contain secrets)
    *.tfplan
    tfplan

    # Variable files with secrets
    *.auto.tfvars
    secret.tfvars

    # IDE files
    .idea/
    .vscode/
    *.swp

    # OS files
    .DS_Store
    Thumbs.db
  EOT
}

# ========================================================================
# SECTION 3: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-project-structure.ps1"
  content  = <<-EOT
    # Project Structure: Terraform vs PowerShell Module Layout
    # =========================================================

    # TERRAFORM PROJECT               | POWERSHELL MODULE
    # --------------------------------|-------------------------------
    # main.tf (resources)             | MyModule.psm1 (functions)
    # variables.tf (inputs)           | Parameters in functions
    # outputs.tf (exports)            | Return values / Write-Output
    # versions.tf (constraints)       | MyModule.psd1 (manifest)
    # locals.tf (internal)            | Private/helper functions
    # terraform.tfvars (config)       | Config.json / .env file
    # modules/ (reusable)             | Nested modules / classes
    # .gitignore                      | .gitignore

    # PowerShell module structure equivalent:
    Write-Host "PowerShell Module Structure:" -ForegroundColor Yellow
    Write-Host @"
    MyModule/
    ├── MyModule.psd1          = versions.tf (metadata, requirements)
    ├── MyModule.psm1          = main.tf (dot-source Public/*.ps1)
    ├── Public/                = outputs.tf (exported functions)
    │   ├── Get-Resource.ps1
    │   ├── New-Resource.ps1
    │   └── Remove-Resource.ps1
    ├── Private/               = locals.tf (internal helpers)
    │   └── Invoke-ApiCall.ps1
    ├── Tests/                 = terraform validate + plan
    │   └── MyModule.Tests.ps1
    └── Config/                = terraform.tfvars
        └── settings.json
    "@

    Write-Host "`nKey Insight:" -ForegroundColor Cyan
    Write-Host "  Both Terraform and PowerShell benefit from:"
    Write-Host "  1. Consistent file naming conventions"
    Write-Host "  2. Separation of concerns (inputs/logic/outputs)"
    Write-Host "  3. Reusable modules for shared functionality"
    Write-Host "  4. Version constraints for dependencies"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "generated_project" {
  description = "Path to the generated example project"
  value       = "./terraform-lab-output/project-structure/example-project/"
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    file_convention = "main.tf + variables.tf + outputs.tf + versions.tf is the standard"
    separation      = "Keep concerns separate: resources, variables, outputs, providers"
    environments    = "Use directories or workspaces to separate dev/staging/prod"
    modules         = "Extract reusable patterns into modules/ directory"
    gitignore       = "Never commit .tfstate, .terraform/, or *.tfplan files"
    enterprise      = "Large projects use environments/ + modules/ + global/ pattern"
  }
}
