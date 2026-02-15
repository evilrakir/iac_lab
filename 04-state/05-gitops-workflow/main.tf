# ╔════════════════════════════════════════════════════════════════════╗
# ║  GITOPS WORKFLOW WITH TERRAFORM                                  ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Git-based Terraform workflows and PR-based changes
# - CI/CD pipeline integration for plan and apply
# - Automated drift detection
# - Branch strategies for infrastructure code
#
# PREREQUISITES:
# - 04-state/04-workspaces
#
# POWERSHELL COMPARISON:
# Like PowerShell script versioning with Git plus automated
# deployment pipelines that run your scripts on merge.

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

    Topic: GitOps Workflow with Terraform

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - GitOps Workflow with Terraform"
}
