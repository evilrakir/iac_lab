# Outputs for Exercise 1: Hello World
# 
# This file demonstrates how to define outputs in Terraform.
# Outputs are similar to PowerShell Write-Output but more structured.

# Basic string output
output "lab_directory_path" {
  description = "Path to the created lab directory"
  value       = local_directory.lab_directory.path
}

# Output with sensitive data (like PowerShell SecureString)
output "welcome_file_path" {
  description = "Path to the welcome file"
  value       = local_file.welcome_file.filename
  sensitive   = false
}

# Output with computed values
output "files_created" {
  description = "List of files created by Terraform"
  value = [
    local_file.welcome_file.filename,
    local_file.terraform_concepts_ps1.filename,
    local_file.terraform_example_tf.filename
  ]
}

# Output with conditional logic
output "backup_status" {
  description = "Status of backup creation"
  value       = var.create_backup ? "Backup files will be created" : "No backup files created"
}

# Output with object structure (like PowerShell custom objects)
output "lab_summary" {
  description = "Summary of the lab configuration"
  value = {
    directory_path = local_directory.lab_directory.path
    student_name   = var.student_name
    environment    = var.environment
    file_count     = var.file_count
    file_types     = var.file_types
    metadata       = var.metadata
    lab_config     = var.lab_config
  }
}

# Output with formatting (like PowerShell formatting)
output "lab_info_formatted" {
  description = "Formatted lab information"
  value = <<-EOT
    ========================================
    TERRAFORM LEARNING LAB SUMMARY
    ========================================
    Student: ${var.student_name}
    Environment: ${var.environment}
    Lab Path: ${local_directory.lab_directory.path}
    Files Created: ${length([
      local_file.welcome_file.filename,
      local_file.terraform_concepts_ps1.filename,
      local_file.terraform_example_tf.filename
    ])}
    File Types: ${join(", ", var.file_types)}
    Backup Enabled: ${var.create_backup}
    ========================================
  EOT
}

# Output with computed attributes
output "file_sizes" {
  description = "Size of created files (in bytes)"
  value = {
    welcome_file = local_file.welcome_file.content_length
    concepts_script = local_file.terraform_concepts_ps1.content_length
    example_config = local_file.terraform_example_tf.content_length
  }
}

# Output with time information
output "creation_time" {
  description = "When the lab was created"
  value       = timestamp()
}

# Output with validation
output "lab_validation" {
  description = "Validation status of the lab"
  value = {
    directory_exists = local_directory.lab_directory.path != null
    files_created    = length([
      local_file.welcome_file.filename,
      local_file.terraform_concepts_ps1.filename,
      local_file.terraform_example_tf.filename
    ]) > 0
    environment_valid = contains(["development", "staging", "production"], var.environment)
    student_name_valid = length(var.student_name) > 0
  }
}
