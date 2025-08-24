# ╔════════════════════════════════════════════════════════════════════╗
# ║  TERRAFORM VARIABLES - YOUR CONFIGURATION INPUTS                  ║
# ║  Understanding Input Variables (like PowerShell Parameters)       ║
# ╚════════════════════════════════════════════════════════════════════╝

# WHAT ARE TERRAFORM VARIABLES?
# ==============================
# Variables are INPUT values for your Terraform configuration.
# They're like PowerShell parameters but with:
#   - Strong typing (string, number, bool, list, map, object)
#   - Default values
#   - Validation rules
#   - Descriptions for documentation

# HOW TO USE VARIABLES:
# =====================
# 1. Define them here (variables.tf)
# 2. Reference them with: var.variable_name
# 3. Override defaults with:
#    - terraform.tfvars file
#    - Command line: terraform apply -var="student_name=John"
#    - Environment variables: TF_VAR_student_name=John

# POWERSHELL COMPARISON:
# ======================
# PowerShell: param([string]$Name = "Default")
# Terraform:  variable "name" { default = "Default" }

# ========================================================================
# EXAMPLE 1: SIMPLE STRING VARIABLE
# ========================================================================
variable "project_name" {
  description = "Name of the project"  # Shows in terraform plan
  type        = string                  # Data type (required in modern Terraform)
  default     = "terraform-lab"         # Default if not provided
}
# PowerShell equivalent:
# param([string]$ProjectName = "terraform-lab")

# ========================================================================
# EXAMPLE 2: PATH VARIABLE (WITH DEFAULT)
# ========================================================================
variable "lab_path" {
  description = "Path where the lab files will be created"
  type        = string
  default     = "./terraform-lab-output"  # Relative path
  
  # NOTE: Terraform automatically creates directories as needed
  # No need to check if directory exists like in PowerShell!
}
# Usage in main.tf: ${var.lab_path}/filename.txt
# PowerShell equivalent: 
# param([string]$LabPath = ".\terraform-lab-output")

# ========================================================================
# EXAMPLE 3: VARIABLE WITH VALIDATION
# ========================================================================
variable "student_name" {
  description = "Your name for personalizing the lab"
  type        = string
  default     = "Terraform Student"
  
  # VALIDATION BLOCK - Enforce rules on input!
  validation {
    condition     = length(var.student_name) > 0  # Must be true
    error_message = "Student name must not be empty."  # Shown if false
  }
}
# PowerShell equivalent:
# param(
#   [ValidateNotNullOrEmpty()]
#   [string]$StudentName = "Terraform Student"
# )

# ========================================================================
# EXAMPLE 4: VARIABLE WITH ALLOWED VALUES (ENUM-LIKE)
# ========================================================================
variable "environment" {
  description = "Environment type for the lab"
  type        = string
  default     = "development"
  
  # Like PowerShell's ValidateSet attribute
  validation {
    condition = contains(
      ["development", "staging", "production"],  # Allowed values
      var.environment                              # Value to check
    )
    error_message = "Environment must be one of: development, staging, production."
  }
}
# PowerShell equivalent:
# param(
#   [ValidateSet('development','staging','production')]
#   [string]$Environment = "development"
# )

# ========================================================================
# EXAMPLE 5: NUMBER VARIABLE WITH RANGE VALIDATION
# ========================================================================
variable "file_count" {
  description = "Number of additional files to create"
  type        = number  # Not 'int' - Terraform uses 'number'
  default     = 3
  
  # Range validation (like PowerShell's ValidateRange)
  validation {
    condition     = var.file_count >= 0 && var.file_count <= 10
    error_message = "File count must be between 0 and 10."
  }
}
# PowerShell equivalent:
# param(
#   [ValidateRange(0,10)]
#   [int]$FileCount = 3
# )

# ========================================================================
# EXAMPLE 6: BOOLEAN VARIABLE (TRUE/FALSE)
# ========================================================================
variable "create_backup" {
  description = "Whether to create backup files"
  type        = bool    # true or false only
  default     = false   # Note: lowercase 'false', not 'False' or '$false'
}
# Usage: terraform apply -var="create_backup=true"
# PowerShell equivalent:
# param([switch]$CreateBackup)  # or [bool]$CreateBackup = $false

# ========================================================================
# EXAMPLE 7: LIST VARIABLE (ARRAY)
# ========================================================================
variable "file_types" {
  description = "Types of files to create"
  type        = list(string)  # Array of strings
  default     = ["txt", "md", "json"]  # Square brackets for lists
}
# Access in main.tf: var.file_types[0] gets "txt"
# Loop in main.tf: for_each = toset(var.file_types)
# PowerShell equivalent:
# param([string[]]$FileTypes = @("txt", "md", "json"))

# ========================================================================
# EXAMPLE 8: MAP VARIABLE (KEY-VALUE PAIRS / HASHTABLE)
# ========================================================================
variable "metadata" {
  description = "Metadata tags for the lab"
  type        = map(string)  # All values must be strings
  default = {
    "CreatedBy"   = "Terraform Learning Lab"
    "Environment" = "development"  
    "Purpose"     = "education"
    # Keys can be with or without quotes
  }
}
# Access in main.tf: var.metadata["CreatedBy"] or var.metadata.CreatedBy
# PowerShell equivalent:
# param([hashtable]$Metadata = @{
#   CreatedBy = "Terraform Learning Lab"
#   Environment = "development"
# })

# ========================================================================
# EXAMPLE 9: OBJECT VARIABLE (COMPLEX STRUCTURED DATA)
# ========================================================================
variable "lab_config" {
  description = "Configuration for the lab"
  type = object({         # Structured object with specific fields
    name        = string  # Each field has its own type
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
# Access in main.tf: var.lab_config.name
# PowerShell equivalent:
# param([PSCustomObject]$LabConfig = [PSCustomObject]@{
#   Name = "terraform-basics"
#   Description = "Basic Terraform concepts lab"
#   Version = "1.0.0"
#   Enabled = $true
# })

# ========================================================================
# HOW TO OVERRIDE THESE VARIABLES
# ========================================================================
# METHOD 1: Create a terraform.tfvars file:
#   student_name = "John Doe"
#   environment = "production"
#
# METHOD 2: Command line:
#   terraform apply -var="student_name=John Doe"
#
# METHOD 3: Environment variables:
#   $env:TF_VAR_student_name = "John Doe"  # PowerShell
#   export TF_VAR_student_name="John Doe"  # Bash
#
# METHOD 4: Interactive prompt:
#   If no default and not provided, Terraform will prompt you!

# TIP: Run 'terraform plan' to see current variable values in use!
