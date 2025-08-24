# Exercise: Docker with Terraform - Container Infrastructure as Code
# Manage Docker containers, images, networks, and volumes with Terraform

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

# ========================================================================
# SECTION 1: DOCKER PROVIDER CONFIGURATION
# ========================================================================

# Configure the Docker provider
provider "docker" {
  # Default configuration uses local Docker daemon
  # For remote Docker:
  # host = "tcp://remote-docker:2376/"
  
  # For Windows Docker Desktop:
  # host = "npipe:////.//pipe//docker_engine"
  
  # For WSL2:
  # host = "unix:///var/run/docker.sock"
}

# ========================================================================
# SECTION 2: VARIABLES
# ========================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "terraform-docker-lab"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "development"
}

variable "nginx_port" {
  description = "Host port for NGINX"
  type        = number
  default     = 8080
}

variable "postgres_port" {
  description = "Host port for PostgreSQL"
  type        = number
  default     = 5432
}

variable "enable_monitoring" {
  description = "Deploy monitoring stack"
  type        = bool
  default     = true
}

# ========================================================================
# SECTION 3: DOCKER NETWORKS
# ========================================================================

# Create a custom bridge network
resource "docker_network" "app_network" {
  name   = "${var.project_name}-network"
  driver = "bridge"
  
  ipam_config {
    subnet  = "172.20.0.0/24"
    gateway = "172.20.0.1"
  }
  
  # Enable inter-container communication
  internal = false
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  labels {
    label = "managed_by"
    value = "terraform"
  }
}

# Create an internal network (no external access)
resource "docker_network" "internal_network" {
  name     = "${var.project_name}-internal"
  driver   = "bridge"
  internal = true  # No external connectivity
  
  ipam_config {
    subnet = "172.21.0.0/24"
  }
}

# ========================================================================
# SECTION 4: DOCKER VOLUMES
# ========================================================================

# Create named volumes for persistent data
resource "docker_volume" "postgres_data" {
  name = "${var.project_name}-postgres-data"
  
  labels {
    label = "service"
    value = "postgresql"
  }
  
  labels {
    label = "environment"
    value = var.environment
  }
}

resource "docker_volume" "app_data" {
  name = "${var.project_name}-app-data"
  
  labels {
    label = "service"
    value = "application"
  }
}

# ========================================================================
# SECTION 5: DOCKER IMAGES
# ========================================================================

# Pull NGINX image
resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true  # Don't remove on destroy
}

# Pull PostgreSQL image
resource "docker_image" "postgres" {
  name         = "postgres:15-alpine"
  keep_locally = true
}

# Pull Redis image
resource "docker_image" "redis" {
  name         = "redis:7-alpine"
  keep_locally = false  # Remove on destroy
}

# Conditional monitoring images
resource "docker_image" "prometheus" {
  count        = var.enable_monitoring ? 1 : 0
  name         = "prom/prometheus:latest"
  keep_locally = false
}

resource "docker_image" "grafana" {
  count        = var.enable_monitoring ? 1 : 0
  name         = "grafana/grafana:latest"
  keep_locally = false
}

# ========================================================================
# SECTION 6: DOCKER CONTAINERS - WEB SERVER
# ========================================================================

# Create NGINX container
resource "docker_container" "nginx" {
  name  = "${var.project_name}-nginx"
  image = docker_image.nginx.image_id
  
  # Port mapping
  ports {
    internal = 80
    external = var.nginx_port
    ip       = "0.0.0.0"
  }
  
  # Network configuration
  networks_advanced {
    name = docker_network.app_network.name
    aliases = ["web", "nginx"]
  }
  
  # Environment variables
  env = [
    "NGINX_HOST=localhost",
    "NGINX_PORT=80"
  ]
  
  # Health check
  healthcheck {
    test         = ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/"]
    interval     = "30s"
    timeout      = "3s"
    start_period = "10s"
    retries      = 3
  }
  
  # Container restart policy
  restart = "unless-stopped"
  must_run = true
  
  # Resource limits
  memory = 128  # MB
  cpu_shares = 256
  
  # Labels
  labels {
    label = "service"
    value = "nginx"
  }
  
  labels {
    label = "environment"
    value = var.environment
  }
  
  # Mount configuration
  volumes {
    host_path      = abspath("${path.module}/nginx.conf")
    container_path = "/etc/nginx/conf.d/default.conf"
    read_only      = true
  }
  
  # Logging configuration
  log_driver = "json-file"
  log_opts = {
    max-size = "10m"
    max-file = "3"
  }
}

# ========================================================================
# SECTION 7: DOCKER CONTAINERS - DATABASE
# ========================================================================

# Create PostgreSQL container
resource "docker_container" "postgres" {
  name  = "${var.project_name}-postgres"
  image = docker_image.postgres.image_id
  
  # Port mapping
  ports {
    internal = 5432
    external = var.postgres_port
  }
  
  # Network configuration
  networks_advanced {
    name = docker_network.app_network.name
    aliases = ["db", "postgres"]
  }
  
  networks_advanced {
    name = docker_network.internal_network.name
  }
  
  # Environment variables
  env = [
    "POSTGRES_DB=appdb",
    "POSTGRES_USER=appuser",
    "POSTGRES_PASSWORD=SecurePass123!",
    "PGDATA=/var/lib/postgresql/data/pgdata"
  ]
  
  # Volume mounts
  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }
  
  # Health check
  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U appuser"]
    interval = "10s"
    timeout  = "5s"
    retries  = 5
  }
  
  restart  = "unless-stopped"
  must_run = true
  
  # Resource limits
  memory = 512
  memory_swap = 1024
  cpu_shares = 512
  
  labels {
    label = "service"
    value = "postgresql"
  }
}

# ========================================================================
# SECTION 8: DOCKER CONTAINERS - CACHE
# ========================================================================

# Create Redis container
resource "docker_container" "redis" {
  name  = "${var.project_name}-redis"
  image = docker_image.redis.image_id
  
  # No external port - internal only
  
  # Network configuration (internal only)
  networks_advanced {
    name = docker_network.internal_network.name
    aliases = ["cache", "redis"]
  }
  
  # Redis configuration
  command = [
    "redis-server",
    "--appendonly", "yes",
    "--maxmemory", "256mb",
    "--maxmemory-policy", "allkeys-lru"
  ]
  
  # Volume for persistence
  volumes {
    volume_name    = docker_volume.app_data.name
    container_path = "/data"
  }
  
  restart  = "unless-stopped"
  must_run = true
  
  # Resource limits
  memory = 256
  cpu_shares = 256
  
  labels {
    label = "service"
    value = "redis"
  }
}

# ========================================================================
# SECTION 9: MONITORING STACK (CONDITIONAL)
# ========================================================================

# Prometheus container
resource "docker_container" "prometheus" {
  count = var.enable_monitoring ? 1 : 0
  
  name  = "${var.project_name}-prometheus"
  image = docker_image.prometheus[0].image_id
  
  ports {
    internal = 9090
    external = 9090
  }
  
  networks_advanced {
    name = docker_network.app_network.name
    aliases = ["prometheus"]
  }
  
  # Mount Prometheus configuration
  volumes {
    host_path      = abspath("${path.module}/prometheus.yml")
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }
  
  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--web.console.libraries=/usr/share/prometheus/console_libraries",
    "--web.console.templates=/usr/share/prometheus/consoles"
  ]
  
  restart = "unless-stopped"
  
  labels {
    label = "monitoring"
    value = "prometheus"
  }
}

# Grafana container
resource "docker_container" "grafana" {
  count = var.enable_monitoring ? 1 : 0
  
  name  = "${var.project_name}-grafana"
  image = docker_image.grafana[0].image_id
  
  ports {
    internal = 3000
    external = 3001
  }
  
  networks_advanced {
    name = docker_network.app_network.name
    aliases = ["grafana"]
  }
  
  env = [
    "GF_SECURITY_ADMIN_PASSWORD=admin",
    "GF_INSTALL_PLUGINS=redis-datasource"
  ]
  
  restart = "unless-stopped"
  
  labels {
    label = "monitoring"
    value = "grafana"
  }
}

# ========================================================================
# SECTION 10: CONFIGURATION FILES
# ========================================================================

# Create NGINX configuration
resource "local_file" "nginx_conf" {
  filename = "${path.module}/nginx.conf"
  content  = <<-EOT
    server {
        listen 80;
        server_name localhost;
        
        location / {
            default_type text/html;
            return 200 '<html>
                <head><title>Terraform Docker Lab</title></head>
                <body>
                    <h1>Welcome to Terraform Docker Lab!</h1>
                    <p>Environment: ${var.environment}</p>
                    <p>Project: ${var.project_name}</p>
                    <hr>
                    <h2>Services Running:</h2>
                    <ul>
                        <li>NGINX on port ${var.nginx_port}</li>
                        <li>PostgreSQL on port ${var.postgres_port}</li>
                        <li>Redis (internal only)</li>
                        ${var.enable_monitoring ? "<li>Prometheus on port 9090</li>" : ""}
                        ${var.enable_monitoring ? "<li>Grafana on port 3001</li>" : ""}
                    </ul>
                </body>
            </html>';
        }
        
        location /health {
            access_log off;
            return 200 "healthy\n";
        }
        
        location /api {
            proxy_pass http://app:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
  EOT
}

# Create Prometheus configuration
resource "local_file" "prometheus_yml" {
  count = var.enable_monitoring ? 1 : 0
  
  filename = "${path.module}/prometheus.yml"
  content  = <<-EOT
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']
      
      - job_name: 'docker'
        static_configs:
          - targets: ['host.docker.internal:9323']
  EOT
}

# Create Docker Compose equivalent documentation
resource "local_file" "docker_compose_equivalent" {
  filename = "${path.module}/docker-compose-equivalent.yml"
  content  = <<-EOT
    # This shows the Docker Compose equivalent of our Terraform configuration
    # Terraform gives us better state management and programmatic control
    
    version: '3.8'
    
    networks:
      app_network:
        driver: bridge
        ipam:
          config:
            - subnet: 172.20.0.0/24
      internal_network:
        driver: bridge
        internal: true
        ipam:
          config:
            - subnet: 172.21.0.0/24
    
    volumes:
      postgres_data:
      app_data:
    
    services:
      nginx:
        image: nginx:alpine
        container_name: ${var.project_name}-nginx
        ports:
          - "${var.nginx_port}:80"
        networks:
          app_network:
            aliases:
              - web
              - nginx
        volumes:
          - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
        restart: unless-stopped
        mem_limit: 128m
        labels:
          service: nginx
          environment: ${var.environment}
      
      postgres:
        image: postgres:15-alpine
        container_name: ${var.project_name}-postgres
        ports:
          - "${var.postgres_port}:5432"
        networks:
          - app_network
          - internal_network
        environment:
          POSTGRES_DB: appdb
          POSTGRES_USER: appuser
          POSTGRES_PASSWORD: SecurePass123!
          PGDATA: /var/lib/postgresql/data/pgdata
        volumes:
          - postgres_data:/var/lib/postgresql/data
        restart: unless-stopped
        mem_limit: 512m
      
      redis:
        image: redis:7-alpine
        container_name: ${var.project_name}-redis
        networks:
          - internal_network
        command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
        volumes:
          - app_data:/data
        restart: unless-stopped
        mem_limit: 256m
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "container_status" {
  description = "Status of all containers"
  value = {
    nginx = {
      id     = docker_container.nginx.id
      name   = docker_container.nginx.name
      ip     = docker_container.nginx.network_data[0].ip_address
      ports  = "http://localhost:${var.nginx_port}"
      status = docker_container.nginx.must_run ? "running" : "stopped"
    }
    
    postgres = {
      id     = docker_container.postgres.id
      name   = docker_container.postgres.name
      ip     = docker_container.postgres.network_data[0].ip_address
      ports  = "postgresql://localhost:${var.postgres_port}"
      status = docker_container.postgres.must_run ? "running" : "stopped"
    }
    
    redis = {
      id     = docker_container.redis.id
      name   = docker_container.redis.name
      ip     = docker_container.redis.network_data[0].ip_address
      ports  = "internal only"
      status = docker_container.redis.must_run ? "running" : "stopped"
    }
    
    monitoring = var.enable_monitoring ? {
      prometheus = "http://localhost:9090"
      grafana    = "http://localhost:3001 (admin/admin)"
    } : null
  }
}

output "networks" {
  description = "Docker networks created"
  value = {
    app_network = {
      name   = docker_network.app_network.name
      subnet = docker_network.app_network.ipam_config[0].subnet
      driver = docker_network.app_network.driver
    }
    
    internal_network = {
      name     = docker_network.internal_network.name
      subnet   = docker_network.internal_network.ipam_config[0].subnet
      internal = docker_network.internal_network.internal
    }
  }
}

output "volumes" {
  description = "Docker volumes created"
  value = {
    postgres_data = docker_volume.postgres_data.name
    app_data      = docker_volume.app_data.name
  }
}

output "quick_commands" {
  description = "Useful Docker commands"
  value = <<-EOT
    
    # View running containers:
    docker ps
    
    # View logs:
    docker logs ${var.project_name}-nginx
    docker logs ${var.project_name}-postgres
    docker logs ${var.project_name}-redis
    
    # Execute commands in containers:
    docker exec -it ${var.project_name}-postgres psql -U appuser -d appdb
    docker exec -it ${var.project_name}-redis redis-cli
    
    # Inspect networks:
    docker network inspect ${var.project_name}-network
    
    # View volumes:
    docker volume ls
    docker volume inspect ${var.project_name}-postgres-data
    
    # Access services:
    NGINX: http://localhost:${var.nginx_port}
    PostgreSQL: psql -h localhost -p ${var.postgres_port} -U appuser -d appdb
    ${var.enable_monitoring ? "Prometheus: http://localhost:9090" : ""}
    ${var.enable_monitoring ? "Grafana: http://localhost:3001 (admin/admin)" : ""}
    
  EOT
}