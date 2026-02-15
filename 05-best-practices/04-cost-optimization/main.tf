# ╔════════════════════════════════════════════════════════════════════╗
# ║  COST OPTIMIZATION STRATEGIES                                    ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Cost estimation with terraform plan
# - Right-sizing resources and lifecycle policies
# - Spot/preemptible instance patterns
# - Infracost integration for cost visibility
#
# PREREQUISITES:
# - 05-best-practices/03-security
#
# POWERSHELL COMPARISON:
# Like PowerShell scripts that audit and right-size cloud resources
# to reduce spending - but built into the provisioning workflow.

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

    Topic: Cost Optimization Strategies

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Cost Optimization Strategies"
}
