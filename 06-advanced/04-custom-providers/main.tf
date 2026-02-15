# ╔════════════════════════════════════════════════════════════════════╗
# ║  CUSTOM TERRAFORM PROVIDERS                                     ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Provider plugin architecture and the Terraform Plugin SDK
# - Building a simple provider in Go
# - Provider schemas and CRUD operations
# - Testing and distributing custom providers
#
# PREREQUISITES:
# - 06-advanced/03-terraform-functions
#
# POWERSHELL COMPARISON:
# Like creating a custom PowerShell module with cmdlets that manage
# external resources - but following the Terraform provider contract.

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

    Topic: Custom Terraform Providers

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Custom Terraform Providers"
}
