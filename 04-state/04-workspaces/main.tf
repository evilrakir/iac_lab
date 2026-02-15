# ╔════════════════════════════════════════════════════════════════════╗
# ║  TERRAFORM WORKSPACES                                            ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Creating and switching between workspaces
# - Workspace-specific variable configurations
# - Using workspaces for dev/staging/prod environments
# - Workspace naming strategies and limitations
#
# PREREQUISITES:
# - 04-state/03-state-locking
#
# POWERSHELL COMPARISON:
# Like PowerShell profiles for different environments or using
# parameter sets to switch between configurations.

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

    Topic: Terraform Workspaces

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Terraform Workspaces"
}
