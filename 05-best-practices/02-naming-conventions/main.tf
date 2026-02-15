# ╔════════════════════════════════════════════════════════════════════╗
# ║  RESOURCE NAMING CONVENTIONS                                     ║
# ║  Consistent naming for maintainable infrastructure              ║
# ╚════════════════════════════════════════════════════════════════════╝

# Consistent naming makes infrastructure easier to identify, search,
# and manage. This exercise demonstrates naming patterns and generates
# resources that follow industry best practices.

# POWERSHELL COMPARISON:
# =====================
# Like PowerShell's Verb-Noun convention (Get-Process, New-Item),
# Terraform has its own naming conventions for resources, variables,
# and outputs that make configs readable and consistent.

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

variable "company" {
  description = "Company or organization abbreviation"
  type        = string
  default     = "acme"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "webapp"
}

variable "environment" {
  description = "Environment short code"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Region short code"
  type        = string
  default     = "eus1"
}

# ========================================================================
# SECTION 1: NAMING CONVENTION PATTERNS
# ========================================================================

locals {
  # Standard naming pattern: {company}-{project}-{environment}-{resource}-{region}
  name_prefix = "${var.company}-${var.project}-${var.environment}"

  # Resource names following the convention
  resource_names = {
    vpc              = "${local.name_prefix}-vpc-${var.region}"
    public_subnet    = "${local.name_prefix}-subnet-public-${var.region}"
    private_subnet   = "${local.name_prefix}-subnet-private-${var.region}"
    security_group   = "${local.name_prefix}-sg-web-${var.region}"
    ec2_instance     = "${local.name_prefix}-ec2-app-${var.region}"
    rds_instance     = "${local.name_prefix}-rds-main-${var.region}"
    s3_bucket        = "${local.name_prefix}-s3-assets-${var.region}"
    load_balancer    = "${local.name_prefix}-alb-web-${var.region}"
    iam_role         = "${local.name_prefix}-role-app"
    lambda_function  = "${local.name_prefix}-fn-api-handler"
  }

  # Standard tags
  common_tags = {
    Company     = var.company
    Project     = var.project
    Environment = var.environment
    Region      = var.region
    ManagedBy   = "terraform"
    CostCenter  = "${var.company}-${var.project}"
  }
}

resource "local_file" "naming_guide" {
  filename = "./terraform-lab-output/naming-conventions/naming-guide.md"
  content  = <<-EOT
    # Terraform Naming Convention Guide

    ## Resource Naming Pattern
    ```
    {company}-{project}-{environment}-{resource_type}-{purpose}-{region}
    ```

    ### Examples
    | Resource | Name |
    |----------|------|
    | VPC | ${local.resource_names.vpc} |
    | Public Subnet | ${local.resource_names.public_subnet} |
    | Security Group | ${local.resource_names.security_group} |
    | EC2 Instance | ${local.resource_names.ec2_instance} |
    | RDS Database | ${local.resource_names.rds_instance} |
    | S3 Bucket | ${local.resource_names.s3_bucket} |
    | Load Balancer | ${local.resource_names.load_balancer} |
    | IAM Role | ${local.resource_names.iam_role} |

    ## HCL Resource Name Conventions
    ```hcl
    # Use snake_case for resource names
    resource "aws_instance" "web_server" { }      # Good
    resource "aws_instance" "WebServer" { }        # Bad
    resource "aws_instance" "web-server" { }       # Bad

    # Use descriptive names (not generic)
    resource "aws_security_group" "web_ingress" { } # Good
    resource "aws_security_group" "sg1" { }          # Bad

    # Use singular nouns
    resource "aws_instance" "app" { }    # Good (even with count)
    resource "aws_instance" "apps" { }   # Bad
    ```

    ## Variable Naming
    ```hcl
    # Use snake_case, descriptive names
    variable "instance_type" { }          # Good
    variable "instanceType" { }           # Bad (camelCase)
    variable "it" { }                     # Bad (too short)

    # Boolean variables start with enable/disable/is/has
    variable "enable_monitoring" { }      # Good
    variable "monitoring" { }             # Less clear

    # Collection variables are plural
    variable "subnet_ids" { }             # Good (list)
    variable "tags" { }                   # Good (map)
    ```

    ## Output Naming
    ```hcl
    # Match the resource attribute pattern
    output "vpc_id" { }                   # Good
    output "instance_public_ip" { }       # Good
    output "db_endpoint" { }              # Good
    ```

    ## Tagging Standards
    Always tag resources with at minimum:
    - **Name**: Human-readable resource name
    - **Environment**: dev / staging / prod
    - **Project**: Project identifier
    - **ManagedBy**: terraform
    - **CostCenter**: For billing attribution
    - **Owner**: Team or individual responsible
  EOT
}

# ========================================================================
# SECTION 2: GENERATED NAMED RESOURCES
# ========================================================================

resource "local_file" "named_resources" {
  filename = "./terraform-lab-output/naming-conventions/named-resources.json"
  content = jsonencode({
    title   = "Resources Following Naming Convention"
    pattern = "{company}-{project}-{environment}-{type}-{purpose}-{region}"
    values = {
      company     = var.company
      project     = var.project
      environment = var.environment
      region      = var.region
    }
    resources = local.resource_names
    tags      = local.common_tags
  })
}

# ========================================================================
# SECTION 3: ANTI-PATTERNS
# ========================================================================

resource "local_file" "anti_patterns" {
  filename = "./terraform-lab-output/naming-conventions/anti-patterns.json"
  content = jsonencode({
    title = "Naming Anti-Patterns to Avoid"
    anti_patterns = [
      {
        bad     = "resource \"aws_instance\" \"instance1\" { }"
        good    = "resource \"aws_instance\" \"web_server\" { }"
        reason  = "Generic names don't convey purpose"
      },
      {
        bad     = "variable \"x\" { }"
        good    = "variable \"instance_type\" { }"
        reason  = "Single-letter variables are unreadable"
      },
      {
        bad     = "resource \"aws_s3_bucket\" \"MyBucket\" { }"
        good    = "resource \"aws_s3_bucket\" \"app_assets\" { }"
        reason  = "Use snake_case, not PascalCase"
      },
      {
        bad     = "tags = { env = \"production\" }"
        good    = "tags = { Environment = \"production\", ManagedBy = \"terraform\" }"
        reason  = "Tags should be standardized and complete"
      },
      {
        bad     = "name = \"my-server\""
        good    = "name = \"$${var.company}-$${var.project}-$${var.environment}-server\""
        reason  = "Hardcoded names don't scale across environments"
      }
    ]
  })
}

# ========================================================================
# SECTION 4: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-naming.ps1"
  content  = <<-EOT
    # Naming Conventions: Terraform vs PowerShell
    # =============================================

    # TERRAFORM                        | POWERSHELL
    # ---------------------------------|-------------------------------
    # snake_case for everything        | PascalCase for functions
    # resource "type" "name" { }       | function Verb-Noun { }
    # variable "enable_logging"        | param([switch]$$EnableLogging)
    # output "vpc_id"                  | Write-Output $$VpcId
    # locals { name_prefix = ... }     | $$NamePrefix = ...

    # PowerShell naming conventions
    Write-Host "PowerShell Naming:" -ForegroundColor Yellow
    Write-Host "  Functions:  Verb-Noun (Get-Process, New-AzVM)"
    Write-Host "  Variables:  PascalCase ($$ServerName, $$IsEnabled)"
    Write-Host "  Parameters: PascalCase (param($$ComputerName))"
    Write-Host "  Modules:    PascalCase (Az.Compute, ActiveDirectory)"

    Write-Host "`nTerraform Naming:" -ForegroundColor Cyan
    Write-Host "  Resources:  snake_case (web_server, main_vpc)"
    Write-Host "  Variables:  snake_case (instance_type, enable_logging)"
    Write-Host "  Outputs:    snake_case (vpc_id, public_ip)"
    Write-Host "  Modules:    kebab-case directories (my-module/)"
    Write-Host "  Providers:  lowercase (aws, azurerm, google)"

    Write-Host "`nBoth ecosystems value consistency!" -ForegroundColor Green
    Write-Host "  Pick a convention and stick with it across the project."
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "resource_names" {
  description = "Generated resource names following convention"
  value       = local.resource_names
}

output "common_tags" {
  description = "Standard tags to apply to all resources"
  value       = local.common_tags
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    pattern     = "Use {company}-{project}-{env}-{type}-{purpose}-{region} for resource names"
    hcl_style   = "Use snake_case for all Terraform identifiers"
    tags        = "Always tag with Environment, Project, ManagedBy, CostCenter"
    descriptive = "Names should convey purpose (web_server, not instance1)"
    consistent  = "Enforce conventions across the team with linting (tflint)"
  }
}
