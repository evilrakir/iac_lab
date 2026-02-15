# ╔════════════════════════════════════════════════════════════════════╗
# ║  DOCKER COMPOSE INTEGRATION                                     ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Terraform vs Docker Compose: when to use each
# - Managing compose files with Terraform
# - Container orchestration patterns
# - Migrating from Compose to Terraform-managed containers
#
# PREREQUISITES:
# - 07-containers/01-docker-basics
#
# POWERSHELL COMPARISON:
# Like PowerShell scripts that manage docker-compose deployments
# with added state tracking and lifecycle management.

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

    Topic: Docker Compose Integration

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Docker Compose Integration"
}
