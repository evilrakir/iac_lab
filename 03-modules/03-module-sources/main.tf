# ╔════════════════════════════════════════════════════════════════════╗
# ║  MODULE SOURCES                                                  ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Local module paths and relative references
# - Git repository sources for modules
# - Terraform Registry module consumption
# - Version constraints and pinning for module sources
#
# PREREQUISITES:
# - 03-modules/02-module-variables
#
# POWERSHELL COMPARISON:
# Like Install-Module from PSGallery vs local module paths -
# multiple ways to source reusable code.

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

    Topic: Module Sources

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Module Sources"
}
