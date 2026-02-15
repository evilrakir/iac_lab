# ╔════════════════════════════════════════════════════════════════════╗
# ║  LOCAL KUBERNETES CLUSTERS                                       ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Provisioning local K8s clusters (minikube, kind, k3s)
# - Cluster configuration and node management
# - Local development workflows with Terraform + K8s
# - Testing infrastructure locally before cloud deployment
#
# PREREQUISITES:
# - 07-containers/02-kubernetes-basics
#
# POWERSHELL COMPARISON:
# Like setting up a local Hyper-V lab environment but for
# containerized workloads with Kubernetes orchestration.

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

    Topic: Local Kubernetes Clusters

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Local Kubernetes Clusters"
}
