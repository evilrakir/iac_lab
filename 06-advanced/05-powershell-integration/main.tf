# ╔════════════════════════════════════════════════════════════════════╗
# ║  POWERSHELL AND TERRAFORM INTEGRATION                           ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Using local-exec provisioners with PowerShell scripts
# - External data sources calling PowerShell for dynamic values
# - Consuming Terraform outputs in PowerShell automation
# - Hybrid automation workflows bridging both tools
#
# PREREQUISITES:
# - 06-advanced/02-conditional-resources
#
# POWERSHELL COMPARISON:
# The bridge between your PowerShell expertise and Terraform -
# learn to use both tools together effectively.

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

    Topic: PowerShell and Terraform Integration

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - PowerShell and Terraform Integration"
}
