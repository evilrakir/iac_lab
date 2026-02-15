# ╔════════════════════════════════════════════════════════════════════╗
# ║  SECURITY BEST PRACTICES                                        ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Managing secrets with Terraform (sensitive variables, Vault)
# - Encrypting state files at rest
# - Least-privilege provider credentials
# - Security scanning for Terraform configurations
#
# PREREQUISITES:
# - 05-best-practices/02-naming-conventions
#
# POWERSHELL COMPARISON:
# Like PowerShell SecureString and credential management
# applied to infrastructure automation secrets.

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

    Topic: Security Best Practices

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Security Best Practices"
}
