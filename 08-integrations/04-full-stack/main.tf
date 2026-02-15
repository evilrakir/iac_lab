# ╔════════════════════════════════════════════════════════════════════╗
# ║  FULL STACK APPLICATION DEPLOYMENT                              ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Deploying complete application stacks with Terraform
# - Frontend + backend + database multi-tier architecture
# - Network topology and security groups
# - End-to-end automation from infrastructure to application
#
# PREREQUISITES:
# - 08-integrations/01-terraform-ansible
#
# POWERSHELL COMPARISON:
# Like a comprehensive PowerShell deployment script that provisions
# everything from servers to applications - but declarative and tracked.

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

    Topic: Full Stack Application Deployment

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Full Stack Application Deployment"
}
