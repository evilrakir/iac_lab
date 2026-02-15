# ╔════════════════════════════════════════════════════════════════════╗
# ║  ON-PREMISE INFRASTRUCTURE (LEGACY)                             ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Managing VMware vSphere with Terraform
# - Hyper-V resource provisioning
# - On-prem to cloud migration patterns
# - Hybrid infrastructure management
#
# PREREQUISITES:
# - 02-providers/01-local-provider
#
# POWERSHELL COMPARISON:
# Like PowerShell scripts managing Hyper-V VMs but with Terraform
# state tracking and declarative syntax for on-premise infrastructure.

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

    Topic: On-Premise Infrastructure

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - On-Premise Infrastructure"
}
