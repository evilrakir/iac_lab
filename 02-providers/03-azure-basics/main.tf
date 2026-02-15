# ╔════════════════════════════════════════════════════════════════════╗
# ║  AZURE PROVIDER BASICS                                           ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Azure Resource Manager (azurerm) provider setup and authentication
# - Creating resource groups, storage accounts, and basic Azure resources
# - Understanding Azure-specific provider configuration
# - Managing Azure credentials safely
#
# PREREQUISITES:
# - 02-providers/01-local-provider
#
# POWERSHELL COMPARISON:
# Like Azure PowerShell (Az module) but declarative - instead of
# New-AzResourceGroup, you describe the desired state and Terraform handles it.

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

    Topic: Azure Provider Basics

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Azure Provider Basics"
}
