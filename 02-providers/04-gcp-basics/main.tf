# ╔════════════════════════════════════════════════════════════════════╗
# ║  GOOGLE CLOUD PROVIDER BASICS                                    ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - GCP provider setup and project configuration
# - Service account authentication
# - Creating basic GCP resources (compute, storage, networking)
# - GCP-specific resource naming and organization
#
# PREREQUISITES:
# - 02-providers/01-local-provider
#
# POWERSHELL COMPARISON:
# Like Google Cloud SDK commands but as infrastructure definitions -
# instead of gcloud compute instances create, you declare the desired state.

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

    Topic: Google Cloud Provider Basics

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Google Cloud Provider Basics"
}
