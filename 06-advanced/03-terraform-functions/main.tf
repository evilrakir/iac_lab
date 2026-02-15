# ╔════════════════════════════════════════════════════════════════════╗
# ║  TERRAFORM BUILT-IN FUNCTIONS                                   ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - String functions (format, join, split, replace, regex)
# - Collection functions (merge, lookup, flatten, keys, values)
# - Type conversion functions (tostring, tolist, tomap)
# - File, path, and encoding functions
#
# PREREQUISITES:
# - 01-basics/05-resources
#
# POWERSHELL COMPARISON:
# Like PowerShell string methods and array manipulation cmdlets
# (-join, -split, Select-Object) built into the language.

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

resource "local_file" "coming_soon" {
  filename = "./terraform-lab-output/coming-soon.txt"
  content  = <<-EOT
    This exercise is coming soon!

    Topic: Terraform Built-in Functions

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Terraform Built-in Functions"
}
