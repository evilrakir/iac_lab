# ╔════════════════════════════════════════════════════════════════════╗
# ║  LOCAL KUBERNETES CLUSTERS                                       ║
# ║  Provisioning local K8s for development and testing              ║
# ╚════════════════════════════════════════════════════════════════════╝

# Before deploying to cloud Kubernetes, you need a local environment
# for development and testing. This exercise covers provisioning local
# K8s clusters with kind, minikube, and k3s - and how Terraform fits
# into the local development workflow.

# POWERSHELL COMPARISON:
# =====================
# Like setting up a local Hyper-V lab for testing:
#   PS:   New-VM -Name "TestServer" -MemoryStartupBytes 2GB
#   Kind: kind create cluster --config cluster.yaml
#   TF:   Terraform provisions apps ON the local cluster

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
  description = "Name for the local K8s cluster"
  type        = string
  default     = "dev-cluster"
}

variable "k8s_version" {
  description = "Kubernetes version to use"
  type        = string
  default     = "1.28"
}

variable "worker_nodes" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

# ========================================================================
# SECTION 1: LOCAL K8S OPTIONS
# ========================================================================

resource "local_file" "local_k8s_options" {
  filename = "./terraform-lab-output/local-k8s/local-kubernetes-options.json"
  content = jsonencode({
    title = "Local Kubernetes Options for Development"
    options = {
      kind = {
        full_name   = "Kubernetes IN Docker"
        description = "Runs K8s nodes as Docker containers"
        best_for    = "CI/CD testing, multi-node clusters, fast startup"
        install     = "choco install kind (Windows) / brew install kind (macOS)"
        pros  = ["Multi-node support", "Fast startup (<60s)", "CI/CD friendly", "Low resource usage"]
        cons  = ["Requires Docker", "No LoadBalancer out of box", "Ephemeral by default"]
        terraform_integration = "Create cluster with kind, then use kubernetes/helm providers"
      }
      minikube = {
        full_name   = "Mini Kubernetes"
        description = "Full K8s cluster in VM or container"
        best_for    = "Learning, single-node development, addon ecosystem"
        install     = "choco install minikube (Windows) / brew install minikube (macOS)"
        pros  = ["Rich addon ecosystem", "Dashboard built-in", "Multiple drivers (Docker, Hyper-V, VirtualBox)"]
        cons  = ["Slower startup", "Single node by default", "Heavier resources"]
        terraform_integration = "Start with minikube, deploy apps with Terraform"
      }
      k3s = {
        full_name   = "Lightweight Kubernetes"
        description = "Rancher's lightweight K8s distribution"
        best_for    = "Edge/IoT, production-like local env, low resources"
        install     = "curl -sfL https://get.k3s.io | sh -"
        pros  = ["Production-grade", "Very lightweight", "Built-in ingress/LB", "Single binary"]
        cons  = ["Linux-native (WSL2 on Windows)", "Different from managed K8s", "Less addon support"]
        terraform_integration = "Provision with Terraform, or deploy apps on existing k3s"
      }
      docker_desktop = {
        full_name   = "Docker Desktop Kubernetes"
        description = "Built-in K8s in Docker Desktop"
        best_for    = "Simplest setup for Docker Desktop users"
        install     = "Enable in Docker Desktop Settings > Kubernetes"
        pros  = ["Zero install (if using Docker Desktop)", "Integrated with Docker", "Persistent"]
        cons  = ["Single node only", "Older K8s versions", "Tied to Docker Desktop license"]
        terraform_integration = "Use kubernetes/helm providers with default kubeconfig"
      }
    }
    recommendation = {
      learning    = "minikube (best docs, dashboard, addons)"
      development = "kind (fast, multi-node, CI/CD compatible)"
      production_like = "k3s (closest to real clusters)"
      windows     = "Docker Desktop K8s or kind (easiest on Windows)"
    }
  })
}

# ========================================================================
# SECTION 2: KIND CLUSTER SETUP
# ========================================================================

resource "local_file" "kind_config" {
  filename = "./terraform-lab-output/local-k8s/kind-cluster-config.yaml"
  content  = <<-EOT
    # kind cluster configuration
    # Usage: kind create cluster --config kind-cluster-config.yaml --name ${var.cluster_name}
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    name: ${var.cluster_name}
    nodes:
    - role: control-plane
      kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
      extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
      - containerPort: 30000
        hostPort: 30000
        protocol: TCP
    # Worker nodes
    - role: worker
    - role: worker
  EOT
}

resource "local_file" "kind_setup_script" {
  filename = "./terraform-lab-output/local-k8s/setup-kind-cluster.ps1"
  content  = <<-EOT
    # Kind Cluster Setup Script for Windows
    # =======================================

    param(
      [string]$$ClusterName = "${var.cluster_name}",
      [string]$$K8sVersion = "${var.k8s_version}",
      [switch]$$Destroy
    )

    # Check prerequisites
    function Test-Prerequisites {
      $$missing = @()
      if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { $$missing += "docker" }
      if (-not (Get-Command kind -ErrorAction SilentlyContinue)) { $$missing += "kind" }
      if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { $$missing += "kubectl" }

      if ($$missing.Count -gt 0) {
        Write-Host "Missing prerequisites: $$($$missing -join ', ')" -ForegroundColor Red
        Write-Host "Install with: choco install $$($$missing -join ' ')" -ForegroundColor Yellow
        return $$false
      }
      return $$true
    }

    if (-not (Test-Prerequisites)) { exit 1 }

    if ($$Destroy) {
      Write-Host "Destroying cluster: $$ClusterName" -ForegroundColor Yellow
      kind delete cluster --name $$ClusterName
      exit 0
    }

    # Check if cluster already exists
    $$existing = kind get clusters 2>$$null | Where-Object { $$_ -eq $$ClusterName }
    if ($$existing) {
      Write-Host "Cluster '$$ClusterName' already exists" -ForegroundColor Yellow
      kubectl cluster-info --context "kind-$$ClusterName"
      exit 0
    }

    # Create cluster
    Write-Host "Creating kind cluster: $$ClusterName" -ForegroundColor Cyan
    kind create cluster --config kind-cluster-config.yaml --name $$ClusterName

    # Verify
    Write-Host "`nCluster ready!" -ForegroundColor Green
    kubectl cluster-info --context "kind-$$ClusterName"
    kubectl get nodes

    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "  1. cd to your Terraform config directory"
    Write-Host "  2. terraform init"
    Write-Host "  3. terraform apply  (deploys apps to the cluster)"
  EOT
}

# ========================================================================
# SECTION 3: TERRAFORM + LOCAL K8S WORKFLOW
# ========================================================================

resource "local_file" "terraform_workflow" {
  filename = "./terraform-lab-output/local-k8s/terraform-local-k8s-workflow.tf"
  content  = <<-EOT
    # ============================================
    # TERRAFORM WORKFLOW WITH LOCAL KUBERNETES
    # ============================================

    # Step 1: Create cluster (outside Terraform)
    # kind create cluster --config kind-cluster-config.yaml

    # Step 2: Configure providers to use local cluster
    provider "kubernetes" {
      config_path    = "~/.kube/config"
      config_context = "kind-${var.cluster_name}"
    }

    provider "helm" {
      kubernetes {
        config_path    = "~/.kube/config"
        config_context = "kind-${var.cluster_name}"
      }
    }

    # Step 3: Deploy namespace
    resource "kubernetes_namespace" "dev" {
      metadata {
        name = "development"
        labels = {
          environment = "local"
          managed_by  = "terraform"
        }
      }
    }

    # Step 4: Deploy application
    resource "helm_release" "app" {
      name       = "my-app"
      chart      = "./charts/my-app"  # Local chart
      namespace  = kubernetes_namespace.dev.metadata[0].name

      set {
        name  = "image.tag"
        value = "latest"
      }

      set {
        name  = "replicaCount"
        value = "1"  # Single replica for local dev
      }

      set {
        name  = "service.type"
        value = "NodePort"  # NodePort for kind
      }
    }

    # Step 5: Deploy supporting services
    resource "helm_release" "redis" {
      name       = "redis"
      repository = "https://charts.bitnami.com/bitnami"
      chart      = "redis"
      version    = "17.0.0"
      namespace  = kubernetes_namespace.dev.metadata[0].name

      set {
        name  = "architecture"
        value = "standalone"
      }

      set {
        name  = "auth.enabled"
        value = "false"  # No auth for local dev
      }
    }

    # Step 6: Local dev workflow commands
    # terraform apply                    # Deploy everything
    # kubectl port-forward svc/my-app 8080:80 -n development
    # terraform apply -target=helm_release.app   # Redeploy app only
    # terraform destroy                  # Clean up everything
  EOT
}

# ========================================================================
# SECTION 4: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-local-k8s.ps1"
  content  = <<-EOT
    # Local Kubernetes: Tools Comparison
    # ====================================

    # TOOL                  | PURPOSE
    # ----------------------|-------------------------------
    # kind / minikube       | Create local K8s cluster
    # kubectl               | Interact with cluster directly
    # helm                  | Deploy packaged applications
    # Terraform             | Manage apps as tracked state
    # PowerShell            | Automation and scripting glue

    # PowerShell workflow for local K8s:
    # 1. Create cluster
    # kind create cluster --name dev

    # 2. Deploy with kubectl
    # kubectl apply -f deployment.yaml

    # 3. Check status
    # kubectl get pods -A | Out-GridView  # PowerShell-style!

    # Terraform workflow for local K8s:
    # 1. Create cluster (kind/minikube - outside TF)
    # 2. terraform init
    # 3. terraform apply  (deploys ALL apps consistently)
    # 4. terraform destroy (clean teardown)

    Write-Host "Local K8s Development Workflow:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Create:  kind create cluster --name dev" -ForegroundColor Cyan
    Write-Host "  Deploy:  terraform apply" -ForegroundColor Green
    Write-Host "  Access:  kubectl port-forward svc/app 8080:80"
    Write-Host "  Debug:   kubectl logs -f deployment/app"
    Write-Host "  Clean:   terraform destroy && kind delete cluster --name dev" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Windows Tips:" -ForegroundColor Magenta
    Write-Host "  - Use Docker Desktop as kind's container runtime"
    Write-Host "  - kubectl output | ConvertFrom-Json for PowerShell piping"
    Write-Host "  - kind load docker-image myapp:latest  (load local images)"
    Write-Host "  - Use port-forward for accessing services locally"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "local_k8s_resources" {
  description = "Generated local K8s reference files"
  value = {
    options    = local_file.local_k8s_options.filename
    kind_config = local_file.kind_config.filename
    setup_script = local_file.kind_setup_script.filename
    workflow   = local_file.terraform_workflow.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    kind       = "kind (K8s IN Docker) is fastest for local multi-node clusters"
    minikube   = "minikube is best for learning with dashboard and addon ecosystem"
    workflow   = "Create cluster with kind/minikube, deploy apps with Terraform"
    dev_cycle  = "terraform apply deploys, port-forward accesses, terraform destroy cleans"
    windows    = "Docker Desktop + kind is the easiest setup on Windows"
    production = "Local clusters mirror production patterns for testing before deploy"
  }
}
