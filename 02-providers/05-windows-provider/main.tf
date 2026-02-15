# ╔════════════════════════════════════════════════════════════════════╗
# ║  WINDOWS PROVIDER CONFIGURATION                                  ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Windows-specific Terraform providers (AD, DNS, DHCP)
# - WinRM configuration for remote management
# - Active Directory resource management with Terraform
# - Windows Server infrastructure as code
#
# PREREQUISITES:
# - 02-providers/01-local-provider
#
# POWERSHELL COMPARISON:
# Like PowerShell DSC resources but managed by Terraform - instead of
# DSC configurations for AD/DNS, you use Terraform's declarative approach.

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

    Topic: Windows Provider Configuration

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Windows Provider Configuration"
}
