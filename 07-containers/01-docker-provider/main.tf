# Docker Provider - Managing Containers with Terraform
# This exercise demonstrates using Terraform to manage Docker containers

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

# Configure the Docker Provider
provider "docker" {
  # For Windows with Docker Desktop
  host = "npipe:////./pipe/docker_engine"
  
  # For Linux/Mac or WSL2
  # host = "unix:///var/run/docker.sock"
}

# Pull a Docker image
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

# Create a Docker network
resource "docker_network" "lab_network" {
  name = "terraform-lab-network"
  driver = "bridge"
  
  ipam_config {
    subnet = "172.28.0.0/16"
    gateway = "172.28.0.1"
  }
}

# Create an Nginx container
resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "terraform-nginx"
  
  ports {
    internal = 80
    external = var.nginx_port
  }
  
  networks_advanced {
    name = docker_network.lab_network.name
    aliases = ["nginx"]
  }
  
  volumes {
    host_path      = abspath("${path.module}/html")
    container_path = "/usr/share/nginx/html"
    read_only      = true
  }
  
  env = [
    "NGINX_HOST=terraform.local",
    "NGINX_PORT=80"
  ]
  
  restart = "unless-stopped"
  
  healthcheck {
    test = ["CMD", "curl", "-f", "http://localhost/"]
    interval = "30s"
    timeout = "3s"
    start_period = "10s"
    retries = 3
  }
}

# Multi-container application example
resource "docker_image" "redis" {
  name         = "redis:alpine"
  keep_locally = true
}

resource "docker_container" "redis" {
  image = docker_image.redis.image_id
  name  = "terraform-redis"
  
  networks_advanced {
    name = docker_network.lab_network.name
    aliases = ["redis"]
  }
  
  restart = "unless-stopped"
  
  command = ["redis-server", "--appendonly", "yes"]
  
  volumes {
    volume_name    = docker_volume.redis_data.name
    container_path = "/data"
  }
}

# Create a Docker volume for persistent data
resource "docker_volume" "redis_data" {
  name = "terraform-redis-data"
  driver = "local"
  
  labels {
    label = "managed-by"
    value = "terraform"
  }
}

# Application container that uses both nginx and redis
resource "docker_image" "app" {
  name = "hashicorp/http-echo:latest"
  keep_locally = true
}

resource "docker_container" "app" {
  count = var.app_replicas
  
  image = docker_image.app.image_id
  name  = "terraform-app-${count.index}"
  
  networks_advanced {
    name = docker_network.lab_network.name
  }
  
  env = [
    "REDIS_HOST=redis",
    "REDIS_PORT=6379"
  ]
  
  command = [
    "-text=Hello from Terraform container ${count.index}!"
  ]
  
  ports {
    internal = 5678
    external = 5000 + count.index
  }
  
  depends_on = [
    docker_container.redis,
    docker_network.lab_network
  ]
}

# Docker Compose integration example (using local-exec)
resource "null_resource" "docker_compose_up" {
  count = var.use_compose ? 1 : 0
  
  provisioner "local-exec" {
    command = "docker-compose -f ${path.module}/docker-compose.yml up -d"
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "docker-compose -f ${path.module}/docker-compose.yml down"
  }
}