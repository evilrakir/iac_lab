# Basic VM Deployment in OpenStack
# This exercise creates a simple virtual machine with security groups and key pairs

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
provider "openstack" {
  # Uses environment variables or provider configuration
}

# Variables for customization
variable "instance_name" {
  description = "Name for the virtual machine"
  type        = string
  default     = "terraform-vm"
}

variable "key_name" {
  description = "Name of the OpenStack key pair to use"
  type        = string
  default     = "terraform-key"
}

variable "flavor_name" {
  description = "Flavor (size) of the virtual machine"
  type        = string
  default     = "m1.small"
}

variable "image_name" {
  description = "Image to use for the virtual machine"
  type        = string
  default     = "Ubuntu 22.04"
}

variable "network_name" {
  description = "Network to attach the VM to"
  type        = string
  default     = "internal"
}

variable "create_floating_ip" {
  description = "Whether to create and assign a floating IP"
  type        = bool
  default     = false
}

# Data sources to find existing resources
data "openstack_images_image_v2" "vm_image" {
  name        = var.image_name
  most_recent = true
}

data "openstack_compute_flavor_v2" "vm_flavor" {
  name = var.flavor_name
}

data "openstack_networking_network_v2" "vm_network" {
  name = var.network_name
}

data "openstack_networking_network_v2" "external" {
  name     = "external"
  external = true
}

# Create a security group for our VM
resource "openstack_networking_secgroup_v2" "vm_secgroup" {
  name        = "${var.instance_name}-secgroup"
  description = "Security group for ${var.instance_name}"

  tags = ["terraform", "lab", "basic-vm"]
}

# Allow SSH access
resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.vm_secgroup.id
  description       = "Allow SSH access"
}

# Allow HTTP access
resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.vm_secgroup.id
  description       = "Allow HTTP access"
}

# Allow HTTPS access
resource "openstack_networking_secgroup_rule_v2" "https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.vm_secgroup.id
  description       = "Allow HTTPS access"
}

# Allow ICMP (ping)
resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.vm_secgroup.id
  description       = "Allow ICMP (ping)"
}

# Create a key pair for SSH access
resource "openstack_compute_keypair_v2" "vm_keypair" {
  name       = var.key_name
  public_key = file("${path.module}/terraform-key.pub")
  
  # If you don't have a key pair, create one with:
  # ssh-keygen -t rsa -b 4096 -f terraform-key -N ""
}

# Create the virtual machine
resource "openstack_compute_instance_v2" "vm" {
  name            = var.instance_name
  image_id        = data.openstack_images_image_v2.vm_image.id
  flavor_id       = data.openstack_compute_flavor_v2.vm_flavor.id
  key_pair        = openstack_compute_keypair_v2.vm_keypair.name
  security_groups = [openstack_networking_secgroup_v2.vm_secgroup.name]

  # Attach to network
  network {
    uuid = data.openstack_networking_network_v2.vm_network.id
  }

  # User data script to install basic packages
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    hostname = var.instance_name
  }))

  # Metadata
  metadata = {
    created_by = "terraform"
    lab        = "basic-vm"
    purpose    = "learning"
  }

  tags = ["terraform", "lab", "vm"]

  # Wait for the instance to be active
  stop_before_destroy = true
}

# Create floating IP if requested
resource "openstack_networking_floatingip_v2" "vm_fip" {
  count = var.create_floating_ip ? 1 : 0
  
  pool = data.openstack_networking_network_v2.external.name
  
  tags = ["terraform", "lab", var.instance_name]
}

# Associate floating IP with the instance
resource "openstack_compute_floatingip_associate_v2" "vm_fip_associate" {
  count = var.create_floating_ip ? 1 : 0
  
  floating_ip = openstack_networking_floatingip_v2.vm_fip[0].address
  instance_id = openstack_compute_instance_v2.vm.id
  
  # Wait for the instance to be fully booted
  depends_on = [openstack_compute_instance_v2.vm]
}

# Outputs
output "instance_info" {
  description = "Information about the created instance"
  value = {
    id               = openstack_compute_instance_v2.vm.id
    name             = openstack_compute_instance_v2.vm.name
    status           = openstack_compute_instance_v2.vm.power_state
    private_ip       = openstack_compute_instance_v2.vm.access_ip_v4
    floating_ip      = var.create_floating_ip ? openstack_networking_floatingip_v2.vm_fip[0].address : null
    security_groups  = openstack_compute_instance_v2.vm.security_groups
    flavor           = data.openstack_compute_flavor_v2.vm_flavor.name
    image            = data.openstack_images_image_v2.vm_image.name
  }
}

output "connection_info" {
  description = "How to connect to the instance"
  value = var.create_floating_ip ? {
    ssh_command = "ssh -i terraform-key ubuntu@${openstack_networking_floatingip_v2.vm_fip[0].address}"
    web_url     = "http://${openstack_networking_floatingip_v2.vm_fip[0].address}"
    ping_test   = "ping ${openstack_networking_floatingip_v2.vm_fip[0].address}"
  } : {
    ssh_command = "ssh -i terraform-key ubuntu@${openstack_compute_instance_v2.vm.access_ip_v4}"
    web_url     = "http://${openstack_compute_instance_v2.vm.access_ip_v4}"
    ping_test   = "ping ${openstack_compute_instance_v2.vm.access_ip_v4}"
    note        = "Connection via private IP only - use floating IP for external access"
  }
}

output "security_group_info" {
  description = "Security group information"
  value = {
    id          = openstack_networking_secgroup_v2.vm_secgroup.id
    name        = openstack_networking_secgroup_v2.vm_secgroup.name
    description = openstack_networking_secgroup_v2.vm_secgroup.description
    rules_count = length(openstack_networking_secgroup_v2.vm_secgroup.rules)
  }
}

output "key_pair_info" {
  description = "Key pair information"
  value = {
    name        = openstack_compute_keypair_v2.vm_keypair.name
    fingerprint = openstack_compute_keypair_v2.vm_keypair.fingerprint
    note        = "Private key is in terraform-key file"
  }
}