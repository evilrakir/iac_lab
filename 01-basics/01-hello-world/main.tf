# Exercise 1: Hello World - Your First Terraform Configuration
# 
# This exercise demonstrates basic Terraform concepts using the local provider.
# The local provider allows you to create local files and directories without
# needing any cloud infrastructure.

# Configure the local provider
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

# Create a simple text file with a welcome message
# Note: local_file automatically creates parent directories
resource "local_file" "welcome_file" {
  filename = "${var.lab_path}/welcome.txt"
  content  = <<-EOT
    Welcome to Terraform Learning Lab!
    
    This file was created by Terraform on ${timestamp()}
    
    Your PowerShell automation skills will transfer well to Terraform:
    - Both use declarative syntax
    - Both support variables and functions
    - Both can be version controlled
    - Both support modular design
    
    Next steps:
    1. Explore the terraform.tfstate file to see how Terraform tracks resources
    2. Try modifying this content and running terraform plan
    3. Use terraform show to inspect the current state
    
    Happy Terraforming! 🌍
  EOT

  # Directory is created automatically with the file
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
