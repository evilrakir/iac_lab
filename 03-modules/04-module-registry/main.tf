# ╔════════════════════════════════════════════════════════════════════╗
# ║  TERRAFORM MODULE REGISTRY                                      ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Discovering modules on the Terraform Registry
# - Using verified and community modules
# - Publishing your own modules to a registry
# - Module versioning and upgrade strategies
#
# PREREQUISITES:
# - 03-modules/03-module-sources
#
# POWERSHELL COMPARISON:
# Like PowerShell Gallery for discovering and sharing reusable code -
# Find-Module, Install-Module, Publish-Module equivalents.

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

    Topic: Terraform Module Registry

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Terraform Module Registry"
}
