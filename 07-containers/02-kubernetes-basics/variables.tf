# Variables for Kubernetes Basics Exercise
# These variables configure the Kubernetes deployment

# Kubernetes connection configuration
variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubernetes_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "docker-desktop"
}

# Basic project configuration
variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "terraform-lab"
  
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

# Application configuration
variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "sample-app"
  
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.app_name))
    error_message = "App name must be a valid Kubernetes resource name."
  }
}

variable "app_version" {
  description = "Version of the application"
  type        = string
  default     = "1.0.0"
}

variable "debug_enabled" {
  description = "Enable debug logging"
  type        = bool
  default     = false
}

# Database configuration
variable "database_host" {
  description = "Database hostname"
  type        = string
  default     = "postgres.default.svc.cluster.local"
}

variable "database_port" {
  description = "Database port"
  type        = number
  default     = 5432
  
  validation {
    condition     = var.database_port > 0 && var.database_port <= 65535
    error_message = "Database port must be between 1 and 65535."
  }
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

# Sensitive configuration (credentials)
variable "app_username" {
  description = "Application username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "app_password" {
  description = "Application password"
  type        = string
  default     = "changeme123"
  sensitive   = true
}

variable "api_key" {
  description = "API key for external services"
  type        = string
  default     = "sk-test-1234567890abcdef"
  sensitive   = true
}

# Deployment configuration
variable "replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
  
  validation {
    condition     = var.replicas >= 1 && var.replicas <= 100
    error_message = "Replicas must be between 1 and 100."
  }
}

# Container configuration
variable "container_image" {
  description = "Container image to deploy"
  type        = string
  default     = "nginx"
}

variable "container_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
  
  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "Container port must be between 1 and 65535."
  }
}

# Resource configuration
variable "resource_limits" {
  description = "Resource limits for containers"
  type = object({
    cpu    = string
    memory = string
  })
  default = {
    cpu    = "500m"
    memory = "512Mi"
  }
}

variable "resource_requests" {
  description = "Resource requests for containers"
  type = object({
    cpu    = string
    memory = string
  })
  default = {
    cpu    = "250m"
    memory = "256Mi"
  }
}

# Service configuration
variable "service_type" {
  description = "Kubernetes service type"
  type        = string
  default     = "ClusterIP"
  
  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.service_type)
    error_message = "Service type must be ClusterIP, NodePort, or LoadBalancer."
  }
}

# Ingress configuration
variable "enable_ingress" {
  description = "Enable ingress for the application"
  type        = bool
  default     = false
}

variable "ingress_host" {
  description = "Hostname for ingress"
  type        = string
  default     = "app.local"
}

# Auto-scaling configuration
variable "enable_autoscaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = false
}

variable "autoscaling" {
  description = "Horizontal pod autoscaling configuration"
  type = object({
    min_replicas              = number
    max_replicas              = number
    target_cpu_percentage     = number
    target_memory_percentage  = number
  })
  default = {
    min_replicas             = 2
    max_replicas             = 10
    target_cpu_percentage    = 70
    target_memory_percentage = 80
  }
  
  validation {
    condition = (
      var.autoscaling.min_replicas >= 1 &&
      var.autoscaling.max_replicas >= var.autoscaling.min_replicas &&
      var.autoscaling.target_cpu_percentage > 0 &&
      var.autoscaling.target_cpu_percentage <= 100 &&
      var.autoscaling.target_memory_percentage > 0 &&
      var.autoscaling.target_memory_percentage <= 100
    )
    error_message = "Invalid autoscaling configuration."
  }
}

# Storage configuration
variable "enable_persistence" {
  description = "Enable persistent storage"
  type        = bool
  default     = false
}

variable "storage_size" {
  description = "Size of persistent storage"
  type        = string
  default     = "10Gi"
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "standard"
}

# Job configuration
variable "run_migration" {
  description = "Run database migration job"
  type        = bool
  default     = false
}

# Backup configuration
variable "enable_backup" {
  description = "Enable backup cron job"
  type        = bool
  default     = false
}

variable "backup_schedule" {
  description = "Cron schedule for backups"
  type        = string
  default     = "0 2 * * *"  # Daily at 2 AM
  
  validation {
    condition     = can(regex("^[0-9*,-/]+ [0-9*,-/]+ [0-9*,-/]+ [0-9*,-/]+ [0-9*,-/]+$", var.backup_schedule))
    error_message = "Backup schedule must be a valid cron expression."
  }
}

# Advanced configuration
variable "node_selector" {
  description = "Node selector for pod placement"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Pod tolerations"
  type = list(object({
    key      = string
    operator = string
    value    = string
    effect   = string
  }))
  default = []
}

variable "affinity_enabled" {
  description = "Enable pod affinity rules"
  type        = bool
  default     = false
}

variable "network_policy_enabled" {
  description = "Enable network policies"
  type        = bool
  default     = false
}

# Monitoring configuration
variable "enable_monitoring" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = true
}

variable "monitoring_port" {
  description = "Port for monitoring metrics"
  type        = number
  default     = 9090
}

# Logging configuration
variable "enable_fluentd" {
  description = "Enable Fluentd logging sidecar"
  type        = bool
  default     = false
}

variable "log_level" {
  description = "Application log level"
  type        = string
  default     = "info"
  
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be debug, info, warn, or error."
  }
}