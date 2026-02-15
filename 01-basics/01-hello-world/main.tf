# ╔════════════════════════════════════════════════════════════════════╗
# ║  TERRAFORM HELLO WORLD - YOUR FIRST CONFIGURATION                 ║
# ║  Learn Infrastructure as Code with detailed explanations          ║
# ╚════════════════════════════════════════════════════════════════════╝

# WHAT IS THIS FILE?
# ==================
# This is a Terraform configuration file (always ends in .tf)
# Think of it like a PowerShell script, but instead of running commands,
# you're describing WHAT you want to exist. Terraform figures out HOW.

# HOW TERRAFORM WORKS:
# ====================
# 1. You write configuration (this file)
# 2. Run 'terraform plan' to preview changes (like -WhatIf)
# 3. Run 'terraform apply' to create/update resources
# 4. Terraform tracks everything in a state file

# ========================================================================
# SECTION 1: TERRAFORM CONFIGURATION BLOCK
# ========================================================================
# This block tells Terraform what providers (plugins) we need.
# Think of providers like PowerShell modules - they add functionality.

terraform {
  # Which providers do we need? (like Import-Module in PowerShell)
  required_providers {
    # We're using the "local" provider to create files on your computer
    # No cloud account needed - perfect for learning!
    local = {
      source  = "hashicorp/local"  # Where to download from (like PSGallery)
      version = "~> 2.4"            # Version constraint (~ means 2.4.x)
    }
  }
  
  # Minimum Terraform version required
  required_version = ">= 1.0"
}

# PROVIDER COMPARISON:
# PowerShell: Install-Module -Name SomeModule -RequiredVersion 2.4
# Terraform:  The terraform block above
# Key Difference: Terraform downloads providers automatically with 'terraform init'

# ========================================================================
# SECTION 2: YOUR FIRST RESOURCE - CREATING A FILE
# ========================================================================
# Resources are the core of Terraform - they represent infrastructure.
# Each resource has:
#   - A TYPE (what kind of thing)
#   - A NAME (your label for it)
#   - ARGUMENTS (configuration)

resource "local_file" "welcome_file" {
  # ANATOMY OF A RESOURCE:
  # resource = keyword that starts a resource block
  # "local_file" = the resource TYPE (from the local provider)
  # "welcome_file" = YOUR name for this specific resource instance
  
  # REQUIRED ARGUMENTS for local_file:
  filename = "${var.lab_path}/welcome.txt"  
  # This uses string interpolation with a variable!
  # ${var.lab_path} gets replaced with the variable value
  # Default: "terraform-lab-output/welcome.txt"
  
  # The content to write to the file
  # <<-EOT is a "heredoc" - allows multi-line strings (like @" "@ in PowerShell)
  content  = <<-EOT
    Welcome to Terraform Learning Lab!
    
    Student: ${var.student_name}
    Environment: ${var.environment}
    Project: ${var.project_name}
    
    This file was created by Terraform on ${timestamp()}
    
    Lab Configuration:
    - Backup Enabled: ${var.create_backup}
    - File Count Setting: ${var.file_count}
    - File Types: ${join(", ", var.file_types)}
    - Lab Version: ${var.lab_config.version}
    
    Metadata Tags:
    ${jsonencode(var.metadata)}
    
    Your PowerShell automation skills will transfer well to Terraform!
  EOT
  
  # Note: The directory is created automatically if it doesn't exist!
  # This is declarative - you say WHAT you want, not HOW to create it
}

# POWERSHELL EQUIVALENT:
# $labPath = "terraform-lab-output"
# $content = @"
# Welcome to Terraform Learning Lab!
# ...
# "@
# New-Item -Path "$labPath\welcome.txt" -ItemType File -Force
# Set-Content -Path "$labPath\welcome.txt" -Value $content
#
# KEY DIFFERENCE: Terraform tracks this file and will:
# - Recreate it if deleted
# - Update it if you change the content
# - Delete it if you remove this resource block

# OPTIONAL: Create backup file based on variable
# This demonstrates conditional resource creation using count
resource "local_file" "backup_file" {
  count    = var.create_backup ? 1 : 0  # Creates 1 if true, 0 if false
  filename = "${var.lab_path}/backup-${formatdate("YYYY-MM-DD", timestamp())}.txt"
  content  = "Backup created for ${var.student_name} in ${var.environment} environment"
}

# Create a PowerShell script that demonstrates Terraform concepts
resource "local_file" "terraform_concepts_ps1" {
  filename = "${var.lab_path}/terraform-concepts.ps1"
  content  = <<-EOT
# PowerShell script demonstrating Terraform concepts
# This script shows how PowerShell and Terraform concepts relate

Write-Host "=== Terraform vs PowerShell Concepts ===" -ForegroundColor Green

# Variables (PowerShell)
$environment = "development"
$region = "us-east-1"

# This is similar to Terraform variables:
# variable "environment" { default = "development" }
# variable "region" { default = "us-east-1" }

Write-Host "Environment: $environment" -ForegroundColor Yellow
Write-Host "Region: $region" -ForegroundColor Yellow

# Conditional logic (PowerShell)
if ($environment -eq "production") {
    $instance_count = 3
} else {
    $instance_count = 1
}

# This is similar to Terraform locals:
# locals {
#   instance_count = var.environment == "production" ? 3 : 1
# }

Write-Host "Instance Count: $instance_count" -ForegroundColor Yellow

# Resource creation simulation (PowerShell)
$resources = @(
    @{ Name = "web-server-1"; Type = "EC2"; Status = "Created" },
    @{ Name = "database-1"; Type = "RDS"; Status = "Created" }
)

# This is similar to Terraform resources:
# resource "aws_instance" "web_server" { ... }
# resource "aws_db_instance" "database" { ... }

Write-Host "`nCreated Resources:" -ForegroundColor Green
$resources | ForEach-Object {
    Write-Host "  - $($_.Name) ($($_.Type)): $($_.Status)" -ForegroundColor Cyan
}

Write-Host "`n=== Key Differences ===" -ForegroundColor Green
Write-Host "PowerShell: Imperative (step-by-step commands)" -ForegroundColor Yellow
Write-Host "Terraform: Declarative (describe desired state)" -ForegroundColor Yellow
Write-Host "PowerShell: Manual state tracking" -ForegroundColor Yellow
Write-Host "Terraform: Automatic state management" -ForegroundColor Yellow
Write-Host "PowerShell: -WhatIf for preview" -ForegroundColor Yellow
Write-Host "Terraform: terraform plan for preview" -ForegroundColor Yellow

Write-Host "`nYour PowerShell skills will help you learn Terraform quickly!" -ForegroundColor Green
  EOT

  # Directory is created automatically with the file
}

# Create a configuration file that shows Terraform syntax
resource "local_file" "terraform_example_tf" {
  filename = "${var.lab_path}/example.tf"
  content  = <<-EOT
# Example Terraform configuration
# This shows the basic structure of a Terraform file

# Variables (like PowerShell parameters)
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-terraform-project"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "development"
}

# Locals (like PowerShell variables)
locals {
  # Conditional logic (like PowerShell if/else)
  instance_count = var.environment == "production" ? 3 : 1
  
  # String interpolation (like PowerShell "$var")
  project_id = "${var.project_name}-${var.environment}"
  
  # Tags (like PowerShell hashtables)
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedBy   = "Learning Lab"
  }
}

# Data sources (like PowerShell Get-* cmdlets)
data "local_file" "existing_file" {
  filename = "existing-file.txt"
}

# Resources (like PowerShell New-* cmdlets)
resource "local_file" "output_file" {
  filename = "output.txt"
  content  = "This file was created by Terraform!"
  
  # Tags (metadata)
  tags = local.common_tags
}

# Outputs (like PowerShell Write-Output)
output "file_path" {
  description = "Path to the created file"
  value       = local_file.output_file.filename
}

output "project_info" {
  description = "Project information"
  value = {
    name    = var.project_name
    env     = var.environment
    id      = local.project_id
    count   = local.instance_count
  }
}
  EOT

  # Directory is created automatically with the file
}


# DEMONSTRATION: Create multiple files using count and variables
# This shows how to use variables to control resource creation
resource "local_file" "example_files" {
  count    = var.file_count  # Creates this many files (default: 3)
  filename = "${var.lab_path}/example-${count.index + 1}.txt"
  content  = <<-EOT
    Example file ${count.index + 1} of ${var.file_count}
    Created for: ${var.student_name}
    Environment: ${var.environment}
    
    This demonstrates:
    - Using count to create multiple resources
    - Using count.index for unique naming
    - Variable interpolation in content
  EOT
}

# DEMONSTRATION: Create files for each file type in the list
resource "local_file" "typed_files" {
  for_each = toset(var.file_types)  # Convert list to set for for_each
  filename = "${var.lab_path}/sample.${each.value}"
  content  = "Sample ${each.value} file created by Terraform"
}
