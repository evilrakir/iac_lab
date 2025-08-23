# OpenStack Provider Configuration
# This exercise introduces the OpenStack provider and basic authentication

terraform {
  required_version = ">= 1.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54.0"
    }
  }
}

# Configure the OpenStack Provider
# Authentication methods (choose one):

# Method 1: Environment variables (recommended for production)
# Export these in your shell or set them in your environment:
# export OS_AUTH_URL="https://your-openstack.example.com:5000/v3"
# export OS_USERNAME="your-username"
# export OS_PASSWORD="your-password"
# export OS_PROJECT_NAME="your-project"
# export OS_USER_DOMAIN_NAME="Default"
# export OS_PROJECT_DOMAIN_NAME="Default"

provider "openstack" {
  # Authentication will use environment variables if available
  # Otherwise, uncomment and fill in the values below
  
  # auth_url    = "https://your-openstack.example.com:5000/v3"
  # user_name   = "your-username"
  # password    = "your-password"
  # tenant_name = "your-project"
  # domain_name = "Default"
  # region      = "RegionOne"
}

# Method 2: Application credentials (recommended for automation)
# provider "openstack" {
#   auth_url                = "https://your-openstack.example.com:5000/v3"
#   application_credential_id     = "your-app-credential-id"
#   application_credential_secret = "your-app-credential-secret"
#   region                  = "RegionOne"
# }

# Data source to test connectivity
data "openstack_identity_auth_scope_v3" "scope" {
  name = "my_scope"
}

# Output the current scope information
output "auth_scope" {
  description = "Current authentication scope"
  value = {
    project_name   = data.openstack_identity_auth_scope_v3.scope.project_name
    project_domain = data.openstack_identity_auth_scope_v3.scope.project_domain_name
    user_name      = data.openstack_identity_auth_scope_v3.scope.user_name
    user_domain    = data.openstack_identity_auth_scope_v3.scope.user_domain_name
    roles          = data.openstack_identity_auth_scope_v3.scope.roles
  }
}

# Data sources to discover available resources
data "openstack_images_image_v2" "ubuntu" {
  name        = "Ubuntu 22.04"
  most_recent = true
  
  # Alternative ways to find images:
  # properties = {
  #   os_distro = "ubuntu"
  # }
}

data "openstack_compute_flavor_v2" "small" {
  name = "m1.small"
  
  # Alternative: find by specs
  # vcpus = 1
  # ram   = 2048
}

data "openstack_networking_network_v2" "external" {
  name     = "external"
  external = true
}

data "openstack_networking_network_v2" "internal" {
  name = "internal"
  
  # Alternative: find private networks
  # external = false
}

# Output discovered resources
output "available_resources" {
  description = "Discovered OpenStack resources"
  value = {
    ubuntu_image = {
      id   = data.openstack_images_image_v2.ubuntu.id
      name = data.openstack_images_image_v2.ubuntu.name
      size = data.openstack_images_image_v2.ubuntu.size_bytes
    }
    small_flavor = {
      id    = data.openstack_compute_flavor_v2.small.id
      name  = data.openstack_compute_flavor_v2.small.name
      vcpus = data.openstack_compute_flavor_v2.small.vcpus
      ram   = data.openstack_compute_flavor_v2.small.ram
      disk  = data.openstack_compute_flavor_v2.small.disk
    }
    external_network = {
      id   = data.openstack_networking_network_v2.external.id
      name = data.openstack_networking_network_v2.external.name
    }
    internal_network = {
      id   = data.openstack_networking_network_v2.internal.id
      name = data.openstack_networking_network_v2.internal.name
    }
  }
}