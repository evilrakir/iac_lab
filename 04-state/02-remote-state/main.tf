# ╔════════════════════════════════════════════════════════════════════╗
# ║  REMOTE STATE BACKENDS                                           ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Configuring remote backends (S3, Azure Storage, GCS)
# - State file security and encryption
# - Migrating from local to remote state
# - Sharing state across teams
#
# PREREQUISITES:
# - 04-state/01-local-state
#
# POWERSHELL COMPARISON:
# Like storing PowerShell DSC configurations in a shared location
# instead of locally - enables team collaboration.

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

    Topic: Remote State Backends

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Remote State Backends"
}
