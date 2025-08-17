# [LEGACY/OPTIONAL] Vagrant Provider for Terraform
# Note: Vagrant is largely superseded by containers but still used in some environments
# This exercise is optional and primarily for environments with existing Vagrant infrastructure

terraform {
  required_providers {
    vagrant = {
      source  = "bmatcuk/vagrant"
      version = "~> 4.1"
    }
  }
  required_version = ">= 1.0"
}

# Note: This provider requires Vagrant to be installed
# Install with: choco install vagrant

variable "use_vagrant" {
  description = "Whether to use Vagrant (legacy option)"
  type        = bool
  default     = false
}

variable "vagrant_box" {
  description = "Vagrant box to use"
  type        = string
  default     = "hashicorp/bionic64"  # Ubuntu 18.04
}

# Vagrant Environment (only created if explicitly enabled)
resource "vagrant_environment" "legacy_vms" {
  count = var.use_vagrant ? 1 : 0
  
  name          = "terraform-legacy-lab"
  working_dir   = path.module
  vagrantfile   = file("${path.module}/Vagrantfile")
  force_destroy = true
}

# Generate Vagrantfile
resource "local_file" "vagrantfile" {
  count = var.use_vagrant ? 1 : 0
  
  filename = "${path.module}/Vagrantfile"
  content  = <<-EOF
# -*- mode: ruby -*-
# vi: set ft=ruby :
# 
# LEGACY NOTICE: This uses Vagrant, which is largely replaced by Docker/Kubernetes
# Consider migrating to container-based solutions in exercises 07-containers

Vagrant.configure("2") do |config|
  # Legacy VM configuration
  config.vm.box = "${var.vagrant_box}"
  
  # Web server VM (legacy style)
  config.vm.define "web" do |web|
    web.vm.hostname = "legacy-web"
    web.vm.network "private_network", ip: "192.168.56.10"
    web.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end
    
    # Legacy provisioning with shell script
    web.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y nginx
      echo "Legacy Vagrant VM - Consider using Docker instead" > /var/www/html/index.html
    SHELL
  end
  
  # Database VM (legacy style)
  config.vm.define "db" do |db|
    db.vm.hostname = "legacy-db"
    db.vm.network "private_network", ip: "192.168.56.11"
    db.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
  end
end
EOF
}

# Migration guide document
resource "local_file" "migration_guide" {
  filename = "${path.module}/MIGRATION_TO_CONTAINERS.md"
  content  = <<-EOF
# Migration Guide: Vagrant to Containers

## Why Migrate from Vagrant?

Vagrant served well for VM-based development, but modern practices favor containers:

| Aspect | Vagrant (Legacy) | Docker/K8s (Modern) |
|--------|-----------------|---------------------|
| Resource Usage | Heavy (full VMs) | Lightweight (shared kernel) |
| Startup Time | Minutes | Seconds |
| Portability | Requires hypervisor | Runs anywhere |
| Ecosystem | Limited | Vast container registry |
| Orchestration | Manual | Kubernetes native |

## Migration Path

### 1. Replace Vagrant VMs with Docker Containers

**Legacy Vagrant:**
```ruby
config.vm.box = "ubuntu/bionic64"
config.vm.provision "shell", inline: "apt-get install -y nginx"
```

**Modern Docker:**
```hcl
resource "docker_container" "nginx" {
  image = "nginx:latest"
  name  = "modern-nginx"
}
```

### 2. Use Docker Compose for Multi-Container

**Legacy Vagrantfile (multiple VMs):**
```ruby
config.vm.define "web" do |web|
  web.vm.network "private_network", ip: "192.168.56.10"
end
config.vm.define "db" do |db|
  db.vm.network "private_network", ip: "192.168.56.11"
end
```

**Modern docker-compose.yml:**
```yaml
services:
  web:
    image: nginx:latest
    networks:
      - app-network
  db:
    image: postgres:14
    networks:
      - app-network
```

### 3. Migrate to Kubernetes for Production

See exercise 07-containers/02-kubernetes-basics for Kubernetes deployment.

## Tools to Help Migration

1. **vagrant-to-docker**: Converts Vagrantfiles to Dockerfiles
2. **kompose**: Converts Docker Compose to Kubernetes
3. **buildpacks**: Auto-generates container images from source

## When Vagrant Might Still Be Needed

- Testing OS-level changes
- Kernel development
- Legacy applications requiring full VMs
- Compliance requirements for VM isolation

For most use cases, containers are the better choice.
EOF
}

# Comparison with modern approach
resource "local_file" "comparison" {
  filename = "${path.module}/vagrant_vs_modern.md"
  content  = <<-EOF
# Vagrant (Legacy) vs Modern Container Approach

## Resource Comparison

### Legacy Vagrant Approach:
- Creates full Virtual Machines
- Requires VirtualBox/VMware/Hyper-V
- Each VM uses 1-4GB RAM minimum
- Slow startup (1-5 minutes)
- Complex networking setup

### Modern Container Approach:
- Creates lightweight containers
- Uses Docker/Podman
- Containers use MB of RAM
- Fast startup (seconds)
- Simple networking with docker networks

## Terraform Code Comparison

### Legacy (this exercise):
```hcl
resource "vagrant_environment" "vms" {
  vagrantfile = file("Vagrantfile")
}
```

### Modern (exercise 07-containers):
```hcl
resource "docker_container" "app" {
  image = "nginx:latest"
  ports {
    internal = 80
    external = 8080
  }
}
```

## Recommendation

Unless you have specific requirements for full VMs, we recommend:
1. Skip this exercise
2. Go directly to 07-containers for modern practices
3. Use this only if maintaining existing Vagrant infrastructure

## If You Must Use Vagrant

Common use cases where Vagrant is still relevant:
- Testing different operating systems
- Simulating complete network environments
- Legacy application compatibility testing
- Learning system administration concepts
EOF
}

output "legacy_notice" {
  value = <<-EOF
  
  ⚠️  LEGACY TECHNOLOGY NOTICE ⚠️
  
  Vagrant is largely superseded by container technologies.
  This exercise is provided for compatibility with existing infrastructure.
  
  For modern practices, see:
  - 07-containers/01-docker-provider (Docker containers)
  - 07-containers/02-kubernetes-basics (Kubernetes)
  
  To proceed with Vagrant (not recommended for new projects):
  1. Install Vagrant: choco install vagrant
  2. Install VirtualBox: choco install virtualbox
  3. Set var.use_vagrant = true
  4. Run: terraform apply
  
  EOF
}