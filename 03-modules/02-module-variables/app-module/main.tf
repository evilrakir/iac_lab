# ╔════════════════════════════════════════════════════════════════════╗
# ║  APP MODULE - Reusable Application Configuration Generator       ║
# ║  This module demonstrates all variable types in action           ║
# ╚════════════════════════════════════════════════════════════════════╝

# This is the MODULE code. It lives in its own directory and is
# called from the parent main.tf using the module block.
# Think of this like a PowerShell function in a .psm1 module file.

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

locals {
  full_name       = "${var.app_name}-${var.environment}"
  is_production   = var.environment == "production"
  actual_replicas = local.is_production ? max(var.replicas, 3) : var.replicas

  config = {
    name        = var.app_name
    environment = var.environment
    replicas    = local.actual_replicas
    logging     = var.enable_logging
    origins     = var.allowed_origins
    tags        = var.tags
    database    = var.database_config
  }
}

# Generate application configuration file
resource "local_file" "app_config" {
  filename = "./terraform-lab-output/modules/${local.full_name}/app-config.json"
  content  = jsonencode(local.config)
}

# Generate deployment manifest
resource "local_file" "deployment" {
  filename = "./terraform-lab-output/modules/${local.full_name}/deployment.yaml"
  content  = yamlencode({
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name   = local.full_name
      labels = merge(var.tags, { app = var.app_name })
    }
    spec = {
      replicas = local.actual_replicas
      template = {
        spec = {
          containers = [{
            name  = var.app_name
            ports = [{ containerPort = var.port_range[0] }]
            env = [
              { name = "ENVIRONMENT", value = var.environment },
              { name = "LOG_ENABLED", value = tostring(var.enable_logging) }
            ]
          }]
        }
      }
    }
  })
}
