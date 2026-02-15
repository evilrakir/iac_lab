# ╔════════════════════════════════════════════════════════════════════╗
# ║  MONITORING AND OBSERVABILITY INTEGRATION                       ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Deploying monitoring infrastructure with Terraform
# - Alerting rules as code
# - Dashboard provisioning (Grafana, CloudWatch)
# - Log aggregation setup
#
# PREREQUISITES:
# - 05-best-practices/04-cost-optimization
#
# POWERSHELL COMPARISON:
# Like PowerShell scripts that configure Windows Event Log monitoring
# and performance counters - but for cloud-native observability.

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

    Topic: Monitoring and Observability Integration

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Monitoring and Observability Integration"
}
