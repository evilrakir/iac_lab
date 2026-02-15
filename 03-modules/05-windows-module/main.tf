# ╔════════════════════════════════════════════════════════════════════╗
# ║  WINDOWS INFRASTRUCTURE MODULES                                  ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Creating Windows-specific reusable modules
# - IIS deployment and configuration modules
# - Windows service management as Terraform modules
# - Active Directory resource modules
#
# PREREQUISITES:
# - 03-modules/04-module-registry
#
# POWERSHELL COMPARISON:
# Like PowerShell DSC composite resources packaged as Terraform modules -
# reusable Windows infrastructure patterns.

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

    Topic: Windows Infrastructure Modules

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Windows Infrastructure Modules"
}
