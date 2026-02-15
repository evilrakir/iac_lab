# ╔════════════════════════════════════════════════════════════════════╗
# ║  MODULE INPUT VARIABLES                                          ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Passing variables to modules with different types
# - Default values and required variables in modules
# - Variable validation within modules
# - Complex variable types (objects, maps) for module configuration
#
# PREREQUISITES:
# - 03-modules/01-simple-module
#
# POWERSHELL COMPARISON:
# Like PowerShell function parameters passed to imported modules -
# param() blocks but for reusable infrastructure components.

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

    Topic: Module Input Variables

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Module Input Variables"
}
