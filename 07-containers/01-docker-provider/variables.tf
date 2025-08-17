variable "nginx_port" {
  description = "External port for Nginx container"
  type        = number
  default     = 8080
}

variable "app_replicas" {
  description = "Number of application container replicas"
  type        = number
  default     = 3
  
  validation {
    condition     = var.app_replicas >= 1 && var.app_replicas <= 10
    error_message = "App replicas must be between 1 and 10."
  }
}

variable "use_compose" {
  description = "Whether to use Docker Compose for additional services"
  type        = bool
  default     = false
}

variable "container_registry" {
  description = "Container registry URL"
  type        = string
  default     = "docker.io"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}