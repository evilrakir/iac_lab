# ╔════════════════════════════════════════════════════════════════════╗
# ║  RESOURCE NAMING CONVENTIONS                                     ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Consistent resource naming strategies
# - Tagging policies and enforcement
# - Using locals for naming patterns
# - Organizational naming standards
#
# PREREQUISITES:
# - 05-best-practices/01-project-structure
#
# POWERSHELL COMPARISON:
# Like PowerShell Verb-Noun naming conventions applied to
# infrastructure resources for consistency.

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

    Topic: Resource Naming Conventions

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Resource Naming Conventions"
}
