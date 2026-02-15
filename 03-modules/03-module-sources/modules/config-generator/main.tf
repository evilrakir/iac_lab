# Simple config generator module used to demonstrate local source paths

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

resource "local_file" "config" {
  filename = "./terraform-lab-output/source-demo/${var.app_name}-${var.environment}.json"
  content  = jsonencode({
    app         = var.app_name
    environment = var.environment
    source_type = "local_path"
    loaded_from = path.module
  })
}

output "config_summary" {
  value = {
    app         = var.app_name
    environment = var.environment
    source      = "local path: ${path.module}"
    config_path = local_file.config.filename
  }
}
