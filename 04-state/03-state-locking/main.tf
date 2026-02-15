# ╔════════════════════════════════════════════════════════════════════╗
# ║  STATE LOCKING AND CONCURRENCY                                   ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - State locking mechanisms and why they matter
# - DynamoDB for AWS state locking
# - Preventing concurrent modifications
# - Force-unlocking state when things go wrong
#
# PREREQUISITES:
# - 04-state/02-remote-state
#
# POWERSHELL COMPARISON:
# Like file locks preventing multiple scripts from modifying
# the same resource simultaneously.

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

    Topic: State Locking and Concurrency

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - State Locking and Concurrency"
}
