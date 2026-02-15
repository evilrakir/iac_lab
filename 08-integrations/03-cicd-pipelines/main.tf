# ╔════════════════════════════════════════════════════════════════════╗
# ║  CI/CD PIPELINE INTEGRATION                                     ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - GitHub Actions workflows for Terraform
# - Azure DevOps pipeline integration
# - Automated plan on PR, apply on merge
# - Drift detection and scheduled applies
#
# PREREQUISITES:
# - 04-state/05-gitops-workflow
#
# POWERSHELL COMPARISON:
# Like PowerShell-based CI/CD scripts but with infrastructure-aware
# pipeline stages that understand plan/apply lifecycle.

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

    Topic: CI/CD Pipeline Integration

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - CI/CD Pipeline Integration"
}
