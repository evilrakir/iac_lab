# ╔════════════════════════════════════════════════════════════════════╗
# ║  HELM CHARTS WITH TERRAFORM                                     ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Helm provider configuration in Terraform
# - Deploying Helm charts as Terraform resources
# - Managing chart values and overrides
# - Release lifecycle management and rollbacks
#
# PREREQUISITES:
# - 07-containers/02-kubernetes-basics
#
# POWERSHELL COMPARISON:
# Like PowerShell package management (Install-Package) but for
# Kubernetes applications - declarative app deployment.

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

    Topic: Helm Charts with Terraform

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Helm Charts with Terraform"
}
