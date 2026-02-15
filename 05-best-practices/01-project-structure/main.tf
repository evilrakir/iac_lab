# ╔════════════════════════════════════════════════════════════════════╗
# ║  PROJECT STRUCTURE AND ORGANIZATION                              ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Organizing Terraform projects for teams
# - File naming conventions (main.tf, variables.tf, outputs.tf)
# - Separating environments with directory structure
# - Mono-repo vs multi-repo approaches
#
# PREREQUISITES:
# - 04-state/01-local-state
#
# POWERSHELL COMPARISON:
# Like organizing PowerShell modules with proper folder structure
# and manifest files (psd1/psm1).

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

    Topic: Project Structure and Organization

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Project Structure and Organization"
}
