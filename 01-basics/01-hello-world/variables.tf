# Variables for Exercise 1: Hello World
# 
# This file demonstrates how to define variables in Terraform.
# Variables are similar to PowerShell parameters but with more structure.

# Project name variable (needed for terraform_example_tf resource)
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "terraform-lab"
}

# Basic string variable with default value
variable "lab_path" {
  description = "Path where the lab files will be created"
  type        = string
  default     = "./terraform-lab-output"
}

# String variable with validation
variable "student_name" {
  description = "Your name for personalizing the lab"
  type        = string
  default     = "Terraform Student"
  
  validation {
    condition     = length(var.student_name) > 0
    error_message = "Student name must not be empty."
  }
}

# String variable with allowed values (like PowerShell ValidateSet)
variable "environment" {
  description = "Environment type for the lab"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

# Number variable with range validation
variable "file_count" {
  description = "Number of additional files to create"
  type        = number
  default     = 3
  
  validation {
    condition     = var.file_count >= 0 && var.file_count <= 10
    error_message = "File count must be between 0 and 10."
  }
}

# Boolean variable (like PowerShell switch parameters)
variable "create_backup" {
  description = "Whether to create backup files"
  type        = bool
  default     = false
}

# List variable (like PowerShell arrays)
variable "file_types" {
  description = "Types of files to create"
  type        = list(string)
  default     = ["txt", "md", "json"]
}

# Map variable (like PowerShell hashtables)
variable "metadata" {
  description = "Metadata tags for the lab"
  type        = map(string)
  default = {
    "CreatedBy"   = "Terraform Learning Lab"
    "Environment" = "development"
    "Purpose"     = "education"
  }
}

# Object variable (like PowerShell custom objects)
variable "lab_config" {
  description = "Configuration for the lab"
  type = object({
    name        = string
    description = string
    version     = string
    enabled     = bool
  })
  default = {
    name        = "terraform-basics"
    description = "Basic Terraform concepts lab"
    version     = "1.0.0"
    enabled     = true
  }
}
