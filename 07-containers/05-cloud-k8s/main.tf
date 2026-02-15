# ╔════════════════════════════════════════════════════════════════════╗
# ║  CLOUD KUBERNETES DEPLOYMENTS                                   ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Deploying managed K8s clusters (EKS, AKS, GKE)
# - Node pool configuration and auto-scaling
# - Cluster networking and ingress setup
# - RBAC and security configuration
#
# PREREQUISITES:
# - 07-containers/04-local-k8s
#
# POWERSHELL COMPARISON:
# Like deploying Azure AKS via Az PowerShell module but as
# repeatable, version-controlled infrastructure code.

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

    Topic: Cloud Kubernetes Deployments

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Cloud Kubernetes Deployments"
}
