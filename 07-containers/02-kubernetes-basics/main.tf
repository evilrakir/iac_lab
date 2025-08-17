# Kubernetes Provider - Managing K8s Resources with Terraform
# Works with any Kubernetes cluster (Minikube, Docker Desktop, EKS, AKS, GKE)

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
  required_version = ">= 1.0"
}

# Configure Kubernetes Provider
# Uses ~/.kube/config by default
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubernetes_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kubernetes_context
  }
}

# Create a namespace
resource "kubernetes_namespace" "app" {
  metadata {
    name = var.namespace
    
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
    
    annotations = {
      "created-by" = "terraform-lab"
      "purpose"    = "learning"
    }
  }
}

# ConfigMap for application configuration
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  
  data = {
    "app.properties" = <<EOF
app.name=${var.app_name}
app.version=${var.app_version}
app.environment=${var.environment}
app.debug=${var.debug_enabled}
EOF
    
    "database.conf" = <<EOF
host=${var.database_host}
port=${var.database_port}
name=${var.database_name}
EOF
  }
}

# Secret for sensitive data
resource "kubernetes_secret" "app_secret" {
  metadata {
    name      = "app-secret"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  
  type = "Opaque"
  
  data = {
    username = base64encode(var.app_username)
    password = base64encode(var.app_password)
    api_key  = base64encode(var.api_key)
  }
}

# Deployment
resource "kubernetes_deployment" "app" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.app.metadata[0].name
    
    labels = {
      app         = var.app_name
      version     = var.app_version
      environment = var.environment
    }
  }
  
  spec {
    replicas = var.replicas
    
    selector {
      match_labels = {
        app = var.app_name
      }
    }
    
    template {
      metadata {
        labels = {
          app     = var.app_name
          version = var.app_version
        }
        
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "9090"
        }
      }
      
      spec {
        container {
          name  = var.app_name
          image = "${var.container_image}:${var.container_tag}"
          
          port {
            container_port = var.container_port
            name          = "http"
          }
          
          env {
            name  = "APP_ENV"
            value = var.environment
          }
          
          env {
            name = "DB_HOST"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "database.conf"
              }
            }
          }
          
          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secret.metadata[0].name
                key  = "password"
              }
            }
          }
          
          resources {
            limits = {
              cpu    = var.resource_limits.cpu
              memory = var.resource_limits.memory
            }
            requests = {
              cpu    = var.resource_requests.cpu
              memory = var.resource_requests.memory
            }
          }
          
          liveness_probe {
            http_get {
              path = "/health"
              port = var.container_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
          
          readiness_probe {
            http_get {
              path = "/ready"
              port = var.container_port
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
          
          volume_mount {
            name       = "config"
            mount_path = "/etc/config"
            read_only  = true
          }
        }
        
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.app_config.metadata[0].name
          }
        }
      }
    }
    
    strategy {
      type = "RollingUpdate"
      
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }
  }
}

# Service
resource "kubernetes_service" "app" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.app.metadata[0].name
    
    labels = {
      app = var.app_name
    }
  }
  
  spec {
    selector = {
      app = var.app_name
    }
    
    port {
      port        = 80
      target_port = var.container_port
      protocol    = "TCP"
    }
    
    type = var.service_type
  }
}

# Ingress (if enabled)
resource "kubernetes_ingress_v1" "app" {
  count = var.enable_ingress ? 1 : 0
  
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.app.metadata[0].name
    
    annotations = {
      "kubernetes.io/ingress.class"                = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "cert-manager.io/cluster-issuer"             = "letsencrypt-prod"
    }
  }
  
  spec {
    rule {
      host = var.ingress_host
      
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          
          backend {
            service {
              name = kubernetes_service.app.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
    
    tls {
      hosts       = [var.ingress_host]
      secret_name = "${var.app_name}-tls"
    }
  }
}

# HorizontalPodAutoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "app" {
  count = var.enable_autoscaling ? 1 : 0
  
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  
  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }
    
    min_replicas = var.autoscaling.min_replicas
    max_replicas = var.autoscaling.max_replicas
    
    metric {
      type = "Resource"
      
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.autoscaling.target_cpu_percentage
        }
      }
    }
    
    metric {
      type = "Resource"
      
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.autoscaling.target_memory_percentage
        }
      }
    }
  }
}

# PersistentVolumeClaim for stateful apps
resource "kubernetes_persistent_volume_claim" "app_data" {
  count = var.enable_persistence ? 1 : 0
  
  metadata {
    name      = "${var.app_name}-data"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  
  spec {
    access_modes = ["ReadWriteOnce"]
    
    resources {
      requests = {
        storage = var.storage_size
      }
    }
    
    storage_class_name = var.storage_class
  }
}

# Job for one-time tasks
resource "kubernetes_job" "migration" {
  count = var.run_migration ? 1 : 0
  
  metadata {
    name      = "${var.app_name}-migration"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  
  spec {
    template {
      metadata {
        labels = {
          job = "migration"
        }
      }
      
      spec {
        container {
          name  = "migration"
          image = "${var.container_image}:${var.container_tag}"
          
          command = ["/bin/sh", "-c"]
          args    = ["echo 'Running database migration...'; sleep 10; echo 'Migration complete!'"]
        }
        
        restart_policy = "Never"
      }
    }
    
    backoff_limit = 3
  }
}

# CronJob for scheduled tasks
resource "kubernetes_cron_job_v1" "backup" {
  count = var.enable_backup ? 1 : 0
  
  metadata {
    name      = "${var.app_name}-backup"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
  
  spec {
    schedule = var.backup_schedule # "0 2 * * *" for daily at 2 AM
    
    job_template {
      metadata {
        labels = {
          job = "backup"
        }
      }
      
      spec {
        template {
          spec {
            container {
              name  = "backup"
              image = "${var.container_image}:${var.container_tag}"
              
              command = ["/bin/sh", "-c"]
              args    = ["echo 'Starting backup...'; sleep 5; echo 'Backup complete!'"]
            }
            
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}