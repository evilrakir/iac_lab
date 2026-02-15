# ╔════════════════════════════════════════════════════════════════════╗
# ║  CHEF AND PUPPET INTEGRATION (LEGACY)                           ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Using Terraform with Chef/Puppet provisioners
# - Configuration management handoff patterns
# - Migration strategies from traditional CM to modern IaC
# - When to combine Terraform with configuration management
#
# PREREQUISITES:
# - 01-basics/05-resources
#
# POWERSHELL COMPARISON:
# Like PowerShell DSC but using older configuration management tools
# (Chef/Puppet) alongside Terraform for legacy environments.

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

    Topic: Chef and Puppet Integration (Legacy)

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Chef and Puppet Integration"
}
