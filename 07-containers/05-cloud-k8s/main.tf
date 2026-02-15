# ╔════════════════════════════════════════════════════════════════════╗
# ║  CLOUD KUBERNETES DEPLOYMENTS                                   ║
# ║  Deploying managed K8s clusters (EKS, AKS, GKE) with Terraform ║
# ╚════════════════════════════════════════════════════════════════════╝

# Managed Kubernetes services handle the control plane so you focus on
# workloads. This exercise generates reference configurations for all
# three major cloud providers' K8s services, showing how Terraform
# provisions both the cluster AND the applications running on it.

# POWERSHELL COMPARISON:
# =====================
# Azure:  New-AzAksCluster -ResourceGroupName "rg" -Name "aks" -NodeCount 3
# AWS:    aws eks create-cluster --name my-cluster --role-arn ...
# TF:     resource "azurerm_kubernetes_cluster" "main" { ... }
# Key:    Terraform manages the FULL lifecycle from cluster to apps

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

# ========================================================================
# VARIABLES
# ========================================================================

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "myapp-cluster"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "node_size" {
  description = "Node instance type/size per cloud"
  type = object({
    aws   = string
    azure = string
    gcp   = string
  })
  default = {
    aws   = "t3.medium"
    azure = "Standard_B2s"
    gcp   = "e2-medium"
  }
}

# ========================================================================
# SECTION 1: AMAZON EKS
# ========================================================================

resource "local_file" "eks_config" {
  filename = "./terraform-lab-output/cloud-k8s/aws-eks.tf"
  content  = <<-EOT
    # ============================================
    # AMAZON EKS (Elastic Kubernetes Service)
    # ============================================

    # EKS requires: VPC, subnets, IAM roles, then the cluster + node groups

    # --- IAM Role for EKS Cluster ---
    resource "aws_iam_role" "eks_cluster" {
      name = "${var.cluster_name}-eks-role"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = { Service = "eks.amazonaws.com" }
        }]
      })
    }

    resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
      policy_arn = "arn:aws:iam::policy/AmazonEKSClusterPolicy"
      role       = aws_iam_role.eks_cluster.name
    }

    # --- EKS Cluster ---
    resource "aws_eks_cluster" "main" {
      name     = "${var.cluster_name}"
      role_arn = aws_iam_role.eks_cluster.arn
      version  = "1.28"

      vpc_config {
        subnet_ids              = var.private_subnet_ids
        endpoint_private_access = true
        endpoint_public_access  = true
      }

      # Enable logging
      enabled_cluster_log_types = ["api", "audit", "authenticator"]
    }

    # --- Node Group ---
    resource "aws_eks_node_group" "workers" {
      cluster_name    = aws_eks_cluster.main.name
      node_group_name = "${var.cluster_name}-workers"
      node_role_arn   = aws_iam_role.eks_node.arn
      subnet_ids      = var.private_subnet_ids
      instance_types  = ["${var.node_size.aws}"]

      scaling_config {
        desired_size = ${var.node_count}
        max_size     = ${var.node_count * 2}
        min_size     = 1
      }

      update_config {
        max_unavailable = 1
      }

      labels = {
        environment = "${var.environment}"
      }
    }

    # --- Connect kubectl ---
    # aws eks update-kubeconfig --name ${var.cluster_name} --region us-east-1
  EOT
}

# ========================================================================
# SECTION 2: AZURE AKS
# ========================================================================

resource "local_file" "aks_config" {
  filename = "./terraform-lab-output/cloud-k8s/azure-aks.tf"
  content  = <<-EOT
    # ============================================
    # AZURE AKS (Azure Kubernetes Service)
    # ============================================

    # AKS is the simplest managed K8s - single resource creates everything

    resource "azurerm_resource_group" "aks" {
      name     = "${var.cluster_name}-rg"
      location = "eastus"
    }

    # --- AKS Cluster ---
    # PS Equivalent: New-AzAksCluster (but with full config control)
    resource "azurerm_kubernetes_cluster" "main" {
      name                = "${var.cluster_name}"
      location            = azurerm_resource_group.aks.location
      resource_group_name = azurerm_resource_group.aks.name
      dns_prefix          = "${var.cluster_name}"
      kubernetes_version  = "1.28"

      # Default node pool (system)
      default_node_pool {
        name       = "system"
        node_count = ${var.node_count}
        vm_size    = "${var.node_size.azure}"

        # Auto-scaling
        enable_auto_scaling = true
        min_count          = 1
        max_count          = ${var.node_count * 2}
      }

      # Managed identity (recommended over SP)
      identity {
        type = "SystemAssigned"
      }

      # Azure AD integration for RBAC
      azure_active_directory_role_based_access_control {
        managed                = true
        azure_rbac_enabled     = true
      }

      # Networking
      network_profile {
        network_plugin = "azure"    # Azure CNI
        network_policy = "calico"   # Network policies
      }

      tags = {
        Environment = "${var.environment}"
        ManagedBy   = "terraform"
      }
    }

    # --- Additional Node Pool (user workloads) ---
    resource "azurerm_kubernetes_cluster_node_pool" "apps" {
      name                  = "apps"
      kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
      vm_size               = "${var.node_size.azure}"
      node_count            = 2
      enable_auto_scaling   = true
      min_count             = 1
      max_count             = 5

      node_labels = {
        workload = "application"
      }
    }

    # --- Connect kubectl ---
    # az aks get-credentials --resource-group ${var.cluster_name}-rg --name ${var.cluster_name}
  EOT
}

# ========================================================================
# SECTION 3: GOOGLE GKE
# ========================================================================

resource "local_file" "gke_config" {
  filename = "./terraform-lab-output/cloud-k8s/google-gke.tf"
  content  = <<-EOT
    # ============================================
    # GOOGLE GKE (Google Kubernetes Engine)
    # ============================================

    # GKE was the first managed K8s - most mature, tightest integration

    # --- GKE Cluster ---
    resource "google_container_cluster" "main" {
      name     = "${var.cluster_name}"
      location = "us-central1"  # Regional cluster (HA)

      # Remove default node pool and create custom one
      remove_default_node_pool = true
      initial_node_count       = 1

      # Networking
      network    = google_compute_network.main.name
      subnetwork = google_compute_subnetwork.k8s.name

      ip_allocation_policy {
        cluster_secondary_range_name  = "pods"
        services_secondary_range_name = "services"
      }

      # Security
      private_cluster_config {
        enable_private_nodes    = true
        enable_private_endpoint = false
        master_ipv4_cidr_block  = "172.16.0.0/28"
      }

      # Workload Identity (recommended)
      workload_identity_config {
        workload_pool = "$${var.project_id}.svc.id.goog"
      }

      # Release channel for auto-upgrades
      release_channel {
        channel = "REGULAR"
      }
    }

    # --- Node Pool ---
    resource "google_container_node_pool" "workers" {
      name     = "workers"
      cluster  = google_container_cluster.main.name
      location = google_container_cluster.main.location

      node_count = ${var.node_count}

      autoscaling {
        min_node_count = 1
        max_node_count = ${var.node_count * 2}
      }

      node_config {
        machine_type = "${var.node_size.gcp}"
        disk_size_gb = 50

        oauth_scopes = [
          "https://www.googleapis.com/auth/cloud-platform",
        ]

        labels = {
          environment = "${var.environment}"
        }

        # Workload Identity
        workload_metadata_config {
          mode = "GKE_METADATA"
        }
      }

      management {
        auto_repair  = true
        auto_upgrade = true
      }
    }

    # --- Connect kubectl ---
    # gcloud container clusters get-credentials ${var.cluster_name} --region us-central1
  EOT
}

# ========================================================================
# SECTION 4: CLOUD K8S COMPARISON
# ========================================================================

resource "local_file" "comparison" {
  filename = "./terraform-lab-output/cloud-k8s/cloud-k8s-comparison.json"
  content = jsonencode({
    title = "Managed Kubernetes Service Comparison"
    services = {
      eks = {
        provider          = "Amazon Web Services"
        terraform_resource = "aws_eks_cluster + aws_eks_node_group"
        complexity        = "High (VPC, IAM roles, node groups all separate)"
        unique_features   = ["Fargate (serverless pods)", "Bottlerocket OS", "EKS Anywhere"]
        authentication    = "aws eks update-kubeconfig or IRSA"
        cost_note         = "$0.10/hour for control plane + node costs"
      }
      aks = {
        provider          = "Microsoft Azure"
        terraform_resource = "azurerm_kubernetes_cluster"
        complexity        = "Low (single resource creates cluster + nodes)"
        unique_features   = ["Azure AD integration", "Virtual Nodes (ACI)", "Free tier control plane"]
        authentication    = "az aks get-credentials or Azure AD"
        cost_note         = "FREE control plane + node costs"
      }
      gke = {
        provider          = "Google Cloud Platform"
        terraform_resource = "google_container_cluster + google_container_node_pool"
        complexity        = "Medium (cluster + node pools)"
        unique_features   = ["Autopilot mode", "Workload Identity", "Most mature service"]
        authentication    = "gcloud container clusters get-credentials"
        cost_note         = "$0.10/hour for control plane (free for one zonal) + node costs"
      }
    }
    common_patterns = [
      "Separate system and application node pools",
      "Enable auto-scaling for worker nodes",
      "Use private clusters for production",
      "Enable audit logging",
      "Use managed identity/IAM roles (not static credentials)",
      "Pin Kubernetes version, use release channels for upgrades"
    ]
  })
}

# ========================================================================
# SECTION 5: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-cloud-k8s.ps1"
  content  = <<-EOT
    # Cloud Kubernetes: Terraform vs CLI/PowerShell
    # ===============================================

    # TERRAFORM                          | CLI / POWERSHELL
    # -----------------------------------|-------------------------------
    # aws_eks_cluster                    | eksctl create cluster
    # azurerm_kubernetes_cluster         | New-AzAksCluster / az aks create
    # google_container_cluster           | gcloud container clusters create
    # Full lifecycle in state            | Manual tracking required
    # Infrastructure + apps together     | Separate tooling for each

    # Azure AKS with PowerShell:
    # New-AzAksCluster ``
    #   -ResourceGroupName "myapp-rg" ``
    #   -Name "myapp-cluster" ``
    #   -NodeCount 3 ``
    #   -NodeVmSize "Standard_B2s" ``
    #   -EnableRBAC
    #
    # Get-AzAksCluster -ResourceGroupName "myapp-rg" -Name "myapp-cluster"
    # Import-AzAksCredential -ResourceGroupName "myapp-rg" -Name "myapp-cluster"

    Write-Host "Cloud Kubernetes with Terraform:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  AWS EKS:   Most complex setup, most customizable"
    Write-Host "  Azure AKS: Simplest to provision, free control plane"
    Write-Host "  Google GKE: Most mature, best auto-management"
    Write-Host ""
    Write-Host "  Terraform Advantage:" -ForegroundColor Cyan
    Write-Host "  - Provision cluster + deploy apps in one workflow"
    Write-Host "  - Same patterns across ALL three clouds"
    Write-Host "  - Network, IAM, cluster, apps all version-controlled"
    Write-Host "  - terraform destroy cleanly removes everything"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "cloud_k8s_resources" {
  description = "Generated cloud K8s reference files"
  value = {
    eks_config  = local_file.eks_config.filename
    aks_config  = local_file.aks_config.filename
    gke_config  = local_file.gke_config.filename
    comparison  = local_file.comparison.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    eks        = "EKS requires VPC + IAM + cluster + node groups (most pieces)"
    aks        = "AKS is simplest - single resource, free control plane, Azure AD integrated"
    gke        = "GKE is most mature with Autopilot mode and Workload Identity"
    terraform  = "Same Terraform patterns work across all three cloud K8s services"
    lifecycle  = "Terraform manages cluster creation, node scaling, AND app deployment"
    production = "Always use private clusters, auto-scaling, managed identity, and audit logging"
  }
}
