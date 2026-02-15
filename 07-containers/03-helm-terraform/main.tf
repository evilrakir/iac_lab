# ╔════════════════════════════════════════════════════════════════════╗
# ║  HELM CHARTS WITH TERRAFORM                                     ║
# ║  Deploying Kubernetes applications using Helm provider           ║
# ╚════════════════════════════════════════════════════════════════════╝

# Helm is the package manager for Kubernetes. The Terraform Helm provider
# lets you deploy Helm charts as Terraform resources, combining the rich
# app ecosystem of Helm with Terraform's state management and lifecycle.

# POWERSHELL COMPARISON:
# =====================
# Like PowerShell's Install-Package / Install-Module but for Kubernetes:
#   PS:   Install-Module Az -Scope CurrentUser -Force
#   Helm: helm install nginx bitnami/nginx --set service.type=LoadBalancer
#   TF:   resource "helm_release" "nginx" { chart = "nginx" ... }

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

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "namespace" {
  description = "Kubernetes namespace for deployments"
  type        = string
  default     = "applications"
}

variable "helm_releases" {
  description = "Helm charts to deploy"
  type = map(object({
    chart      = string
    repository = string
    version    = string
    values     = map(string)
  }))
  default = {
    nginx = {
      chart      = "nginx"
      repository = "https://charts.bitnami.com/bitnami"
      version    = "15.0.0"
      values = {
        "service.type"   = "ClusterIP"
        "replicaCount"   = "2"
      }
    }
    redis = {
      chart      = "redis"
      repository = "https://charts.bitnami.com/bitnami"
      version    = "17.0.0"
      values = {
        "architecture"       = "standalone"
        "auth.enabled"       = "false"
      }
    }
    prometheus = {
      chart      = "kube-prometheus-stack"
      repository = "https://prometheus-community.github.io/helm-charts"
      version    = "45.0.0"
      values = {
        "grafana.enabled"          = "true"
        "alertmanager.enabled"     = "true"
      }
    }
  }
}

# ========================================================================
# SECTION 1: HELM PROVIDER CONFIGURATION
# ========================================================================

resource "local_file" "helm_provider" {
  filename = "./terraform-lab-output/helm-terraform/helm-provider-config.tf"
  content  = <<-EOT
    # ============================================
    # HELM PROVIDER CONFIGURATION
    # ============================================

    terraform {
      required_providers {
        helm = {
          source  = "hashicorp/helm"
          version = "~> 2.12"
        }
        kubernetes = {
          source  = "hashicorp/kubernetes"
          version = "~> 2.25"
        }
      }
    }

    # --- Method 1: Use kubeconfig (local development) ---
    provider "helm" {
      kubernetes {
        config_path = "~/.kube/config"
        # config_context = "my-cluster"  # Optional: specific context
      }
    }

    # --- Method 2: In-cluster (CI/CD / running in K8s) ---
    # provider "helm" {
    #   kubernetes {
    #     host                   = var.cluster_endpoint
    #     cluster_ca_certificate = base64decode(var.cluster_ca)
    #     token                  = var.cluster_token
    #   }
    # }

    # --- Method 3: From EKS/AKS/GKE module output ---
    # provider "helm" {
    #   kubernetes {
    #     host                   = module.eks.cluster_endpoint
    #     cluster_ca_certificate = base64decode(module.eks.cluster_ca)
    #     exec {
    #       api_version = "client.authentication.k8s.io/v1beta1"
    #       command     = "aws"
    #       args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    #     }
    #   }
    # }
  EOT
}

# ========================================================================
# SECTION 2: HELM RELEASE EXAMPLES
# ========================================================================

resource "local_file" "helm_releases" {
  filename = "./terraform-lab-output/helm-terraform/helm-releases.tf"
  content  = <<-EOT
    # ============================================
    # DEPLOYING HELM CHARTS WITH TERRAFORM
    # ============================================

    # --- Namespace for all releases ---
    resource "kubernetes_namespace" "apps" {
      metadata {
        name = "${var.namespace}"
        labels = {
          environment = "${var.environment}"
          managed_by  = "terraform"
        }
      }
    }

    # --- NGINX Ingress Controller ---
    # Equivalent to: helm install nginx-ingress ingress-nginx/ingress-nginx
    resource "helm_release" "nginx_ingress" {
      name       = "nginx-ingress"
      repository = "https://kubernetes.github.io/ingress-nginx"
      chart      = "ingress-nginx"
      version    = "4.8.0"
      namespace  = kubernetes_namespace.apps.metadata[0].name

      set {
        name  = "controller.replicaCount"
        value = "2"
      }

      set {
        name  = "controller.service.type"
        value = "LoadBalancer"
      }

      set {
        name  = "controller.metrics.enabled"
        value = "true"
      }

      # Wait for deployment to be ready
      wait    = true
      timeout = 300

      # Values can also come from a file
      # values = [file("nginx-values.yaml")]
    }

    # --- cert-manager for TLS ---
    resource "helm_release" "cert_manager" {
      name       = "cert-manager"
      repository = "https://charts.jetstack.io"
      chart      = "cert-manager"
      version    = "1.13.0"
      namespace  = "cert-manager"
      create_namespace = true

      set {
        name  = "installCRDs"
        value = "true"
      }
    }

    # --- Monitoring Stack ---
    resource "helm_release" "prometheus" {
      name       = "monitoring"
      repository = "https://prometheus-community.github.io/helm-charts"
      chart      = "kube-prometheus-stack"
      version    = "45.0.0"
      namespace  = "monitoring"
      create_namespace = true

      set {
        name  = "grafana.adminPassword"
        value = var.grafana_password
      }

      set {
        name  = "grafana.service.type"
        value = "ClusterIP"
      }

      set {
        name  = "prometheus.prometheusSpec.retention"
        value = "7d"
      }

      # Use a values file for complex configuration
      values = [
        yamlencode({
          alertmanager = {
            config = {
              route = {
                receiver = "slack"
              }
            }
          }
        })
      ]
    }

    # --- Dynamic releases from variable ---
    # resource "helm_release" "apps" {
    #   for_each = var.helm_releases
    #
    #   name       = each.key
    #   repository = each.value.repository
    #   chart      = each.value.chart
    #   version    = each.value.version
    #   namespace  = kubernetes_namespace.apps.metadata[0].name
    #
    #   dynamic "set" {
    #     for_each = each.value.values
    #     content {
    #       name  = set.key
    #       value = set.value
    #     }
    #   }
    # }
  EOT
}

# ========================================================================
# SECTION 3: HELM VALUES MANAGEMENT
# ========================================================================

resource "local_file" "helm_values" {
  filename = "./terraform-lab-output/helm-terraform/helm-values-patterns.md"
  content  = <<-EOT
    # Helm Values Management in Terraform

    ## Method 1: Inline set blocks
    ```hcl
    resource "helm_release" "nginx" {
      # ...
      set {
        name  = "replicaCount"
        value = "3"
      }
    }
    ```
    Best for: Simple values, small number of overrides

    ## Method 2: values argument with yamlencode
    ```hcl
    resource "helm_release" "nginx" {
      # ...
      values = [
        yamlencode({
          replicaCount = 3
          service = {
            type = "LoadBalancer"
            annotations = {
              "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
            }
          }
        })
      ]
    }
    ```
    Best for: Complex nested values, keeping Terraform as source of truth

    ## Method 3: External YAML file
    ```hcl
    resource "helm_release" "nginx" {
      # ...
      values = [file("$${path.module}/values/nginx-${var.environment}.yaml")]
    }
    ```
    Best for: Large configs, environment-specific value files

    ## Method 4: templatefile for dynamic values
    ```hcl
    resource "helm_release" "nginx" {
      # ...
      values = [
        templatefile("$${path.module}/values/nginx.yaml.tpl", {
          domain    = var.domain_name
          replicas  = var.environment == "prod" ? 3 : 1
          image_tag = var.app_version
        })
      ]
    }
    ```
    Best for: Values that depend on Terraform variables/outputs

    ## Method 5: Sensitive values
    ```hcl
    resource "helm_release" "app" {
      # ...
      set_sensitive {
        name  = "database.password"
        value = var.db_password
      }
    }
    ```
    Best for: Passwords, API keys, secrets

    ## Helm Release Lifecycle
    | Terraform Command  | Helm Equivalent |
    |-------------------|-----------------|
    | terraform apply   | helm install / helm upgrade |
    | terraform destroy | helm uninstall |
    | terraform plan    | helm diff (plugin) |
    | terraform import  | Import existing release |
  EOT
}

# ========================================================================
# SECTION 4: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-helm.ps1"
  content  = <<-EOT
    # Helm: Terraform vs CLI Approaches
    # ===================================

    # TERRAFORM                        | HELM CLI
    # ---------------------------------|-------------------------------
    # helm_release resource            | helm install / helm upgrade
    # terraform destroy                | helm uninstall
    # terraform plan                   | helm diff (plugin)
    # set { name = "key" value = "v" } | --set key=value
    # values = [file("v.yaml")]        | -f values.yaml
    # version = "1.0.0"                | --version 1.0.0
    # create_namespace = true          | --create-namespace

    # Helm CLI from PowerShell:
    # helm repo add bitnami https://charts.bitnami.com/bitnami
    # helm repo update
    # helm search repo bitnami/nginx
    #
    # helm install my-nginx bitnami/nginx ``
    #   --namespace apps ``
    #   --create-namespace ``
    #   --set replicaCount=2 ``
    #   --set service.type=LoadBalancer
    #
    # helm list --all-namespaces
    # helm status my-nginx -n apps
    # helm upgrade my-nginx bitnami/nginx --set replicaCount=3
    # helm rollback my-nginx 1
    # helm uninstall my-nginx -n apps

    Write-Host "Helm: Terraform vs CLI" -ForegroundColor Yellow
    Write-Host "  CLI: Quick deployments, interactive management"
    Write-Host "  Terraform: State-tracked, reproducible, CI/CD friendly"
    Write-Host ""
    Write-Host "  Why use Terraform for Helm?" -ForegroundColor Cyan
    Write-Host "  - Deploy infra + apps in one terraform apply"
    Write-Host "  - Values managed alongside infrastructure code"
    Write-Host "  - Dependency ordering (cert-manager before app)"
    Write-Host "  - Consistent state tracking across everything"
    Write-Host "  - PR-based review for chart version changes"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "helm_resources" {
  description = "Generated Helm reference files"
  value = {
    provider_config = local_file.helm_provider.filename
    releases        = local_file.helm_releases.filename
    values_patterns = local_file.helm_values.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    helm_provider     = "hashicorp/helm provider deploys charts as Terraform resources"
    state_tracked     = "Helm releases are tracked in Terraform state alongside infrastructure"
    values_management = "Use set blocks for simple, yamlencode for complex, files for large configs"
    lifecycle         = "terraform apply = helm install/upgrade, terraform destroy = helm uninstall"
    dependencies      = "Terraform handles ordering: namespace before release, cert-manager before app"
    best_practice     = "Pin chart versions, use create_namespace, set wait = true for production"
  }
}
