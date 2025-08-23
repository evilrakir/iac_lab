# Advanced Networking and Security Groups in OpenStack
# This exercise creates a custom network topology with multiple subnets and advanced security

terraform {
  required_version = ">= 1.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54.0"
    }
  }
}

provider "openstack" {
  # Uses environment variables or provider configuration
}

# Variables
variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "terraform-network"
}

variable "web_instance_count" {
  description = "Number of web server instances"
  type        = number
  default     = 2
}

variable "database_instance_count" {
  description = "Number of database instances"
  type        = number
  default     = 1
}

# Data sources
data "openstack_images_image_v2" "ubuntu" {
  name        = "Ubuntu 22.04"
  most_recent = true
}

data "openstack_compute_flavor_v2" "small" {
  name = "m1.small"
}

data "openstack_networking_network_v2" "external" {
  name     = "external"
  external = true
}

# Create a custom network
resource "openstack_networking_network_v2" "private_network" {
  name           = "${var.project_name}-network"
  admin_state_up = "true"
  
  tags = ["terraform", "lab", "networking"]
}

# Create web subnet
resource "openstack_networking_subnet_v2" "web_subnet" {
  name       = "${var.project_name}-web-subnet"
  network_id = openstack_networking_network_v2.private_network.id
  cidr       = "10.0.1.0/24"
  ip_version = 4
  
  allocation_pool {
    start = "10.0.1.10"
    end   = "10.0.1.200"
  }
  
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
  
  tags = ["terraform", "web", "public"]
}

# Create database subnet
resource "openstack_networking_subnet_v2" "db_subnet" {
  name       = "${var.project_name}-db-subnet"
  network_id = openstack_networking_network_v2.private_network.id
  cidr       = "10.0.2.0/24"
  ip_version = 4
  
  allocation_pool {
    start = "10.0.2.10"
    end   = "10.0.2.200"
  }
  
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
  
  tags = ["terraform", "database", "private"]
}

# Create router for external connectivity
resource "openstack_networking_router_v2" "router" {
  name                = "${var.project_name}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
  
  tags = ["terraform", "lab"]
}

# Attach web subnet to router
resource "openstack_networking_router_interface_v2" "web_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.web_subnet.id
}

# Attach database subnet to router
resource "openstack_networking_router_interface_v2" "db_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.db_subnet.id
}

# Security Groups

# Web server security group
resource "openstack_networking_secgroup_v2" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers"
  
  tags = ["terraform", "web", "security"]
}

# SSH access for web servers
resource "openstack_networking_secgroup_rule_v2" "web_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
  description       = "Allow SSH from anywhere"
}

# HTTP access for web servers
resource "openstack_networking_secgroup_rule_v2" "web_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
  description       = "Allow HTTP from anywhere"
}

# HTTPS access for web servers
resource "openstack_networking_secgroup_rule_v2" "web_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
  description       = "Allow HTTPS from anywhere"
}

# Database security group
resource "openstack_networking_secgroup_v2" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for database servers"
  
  tags = ["terraform", "database", "security"]
}

# SSH access for database servers (restricted to web subnet)
resource "openstack_networking_secgroup_rule_v2" "db_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = openstack_networking_subnet_v2.web_subnet.cidr
  security_group_id = openstack_networking_secgroup_v2.db_sg.id
  description       = "Allow SSH from web subnet only"
}

# MySQL access from web servers
resource "openstack_networking_secgroup_rule_v2" "db_mysql" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_group_id   = openstack_networking_secgroup_v2.web_sg.id
  security_group_id = openstack_networking_secgroup_v2.db_sg.id
  description       = "Allow MySQL from web security group"
}

# PostgreSQL access from web servers
resource "openstack_networking_secgroup_rule_v2" "db_postgresql" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5432
  port_range_max    = 5432
  remote_group_id   = openstack_networking_secgroup_v2.web_sg.id
  security_group_id = openstack_networking_secgroup_v2.db_sg.id
  description       = "Allow PostgreSQL from web security group"
}

# Bastion host security group
resource "openstack_networking_secgroup_v2" "bastion_sg" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security group for bastion host"
  
  tags = ["terraform", "bastion", "security"]
}

# SSH access for bastion
resource "openstack_networking_secgroup_rule_v2" "bastion_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.bastion_sg.id
  description       = "Allow SSH from anywhere"
}

# ICMP rules for all security groups
resource "openstack_networking_secgroup_rule_v2" "web_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
  description       = "Allow ICMP"
}

resource "openstack_networking_secgroup_rule_v2" "db_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "10.0.0.0/16"
  security_group_id = openstack_networking_secgroup_v2.db_sg.id
  description       = "Allow ICMP from private networks"
}

resource "openstack_networking_secgroup_rule_v2" "bastion_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.bastion_sg.id
  description       = "Allow ICMP"
}

# Key pair for all instances
resource "openstack_compute_keypair_v2" "lab_keypair" {
  name       = "${var.project_name}-keypair"
  public_key = file("${path.module}/terraform-key.pub")
}

# Bastion host in web subnet
resource "openstack_compute_instance_v2" "bastion" {
  name            = "${var.project_name}-bastion"
  image_id        = data.openstack_images_image_v2.ubuntu.id
  flavor_id       = data.openstack_compute_flavor_v2.small.id
  key_pair        = openstack_compute_keypair_v2.lab_keypair.name
  security_groups = [openstack_networking_secgroup_v2.bastion_sg.name]

  network {
    uuid        = openstack_networking_network_v2.private_network.id
    fixed_ip_v4 = "10.0.1.10"
  }

  user_data = base64encode(templatefile("${path.module}/bastion-user-data.sh", {
    hostname = "${var.project_name}-bastion"
  }))

  metadata = {
    role       = "bastion"
    created_by = "terraform"
    lab        = "networking"
  }

  tags = ["terraform", "bastion", "management"]
}

# Web servers
resource "openstack_compute_instance_v2" "web_servers" {
  count           = var.web_instance_count
  name            = "${var.project_name}-web-${count.index + 1}"
  image_id        = data.openstack_images_image_v2.ubuntu.id
  flavor_id       = data.openstack_compute_flavor_v2.small.id
  key_pair        = openstack_compute_keypair_v2.lab_keypair.name
  security_groups = [openstack_networking_secgroup_v2.web_sg.name]

  network {
    uuid = openstack_networking_network_v2.private_network.id
  }

  user_data = base64encode(templatefile("${path.module}/web-user-data.sh", {
    hostname    = "${var.project_name}-web-${count.index + 1}"
    server_id   = count.index + 1
    db_servers  = join(",", openstack_compute_instance_v2.db_servers[*].access_ip_v4)
  }))

  metadata = {
    role       = "web"
    created_by = "terraform"
    lab        = "networking"
    tier       = "frontend"
  }

  tags = ["terraform", "web", "frontend"]

  depends_on = [openstack_compute_instance_v2.db_servers]
}

# Database servers
resource "openstack_compute_instance_v2" "db_servers" {
  count           = var.database_instance_count
  name            = "${var.project_name}-db-${count.index + 1}"
  image_id        = data.openstack_images_image_v2.ubuntu.id
  flavor_id       = data.openstack_compute_flavor_v2.small.id
  key_pair        = openstack_compute_keypair_v2.lab_keypair.name
  security_groups = [openstack_networking_secgroup_v2.db_sg.name]

  network {
    uuid = openstack_networking_network_v2.private_network.id
  }

  user_data = base64encode(templatefile("${path.module}/db-user-data.sh", {
    hostname  = "${var.project_name}-db-${count.index + 1}"
    server_id = count.index + 1
  }))

  metadata = {
    role       = "database"
    created_by = "terraform"
    lab        = "networking"
    tier       = "backend"
  }

  tags = ["terraform", "database", "backend"]
}

# Floating IP for bastion host
resource "openstack_networking_floatingip_v2" "bastion_fip" {
  pool = data.openstack_networking_network_v2.external.name
  tags = ["terraform", "bastion"]
}

# Associate floating IP with bastion
resource "openstack_compute_floatingip_associate_v2" "bastion_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.bastion_fip.address
  instance_id = openstack_compute_instance_v2.bastion.id
}

# Floating IPs for web servers
resource "openstack_networking_floatingip_v2" "web_fips" {
  count = var.web_instance_count
  pool  = data.openstack_networking_network_v2.external.name
  tags  = ["terraform", "web", "web-${count.index + 1}"]
}

# Associate floating IPs with web servers
resource "openstack_compute_floatingip_associate_v2" "web_fip_associate" {
  count       = var.web_instance_count
  floating_ip = openstack_networking_floatingip_v2.web_fips[count.index].address
  instance_id = openstack_compute_instance_v2.web_servers[count.index].id
}

# Outputs
output "network_info" {
  description = "Network topology information"
  value = {
    network_name = openstack_networking_network_v2.private_network.name
    network_id   = openstack_networking_network_v2.private_network.id
    web_subnet   = {
      name = openstack_networking_subnet_v2.web_subnet.name
      cidr = openstack_networking_subnet_v2.web_subnet.cidr
    }
    db_subnet = {
      name = openstack_networking_subnet_v2.db_subnet.name
      cidr = openstack_networking_subnet_v2.db_subnet.cidr
    }
    router_name = openstack_networking_router_v2.router.name
  }
}

output "bastion_info" {
  description = "Bastion host connection information"
  value = {
    name        = openstack_compute_instance_v2.bastion.name
    private_ip  = openstack_compute_instance_v2.bastion.access_ip_v4
    public_ip   = openstack_networking_floatingip_v2.bastion_fip.address
    ssh_command = "ssh -i terraform-key ubuntu@${openstack_networking_floatingip_v2.bastion_fip.address}"
  }
}

output "web_servers_info" {
  description = "Web servers information"
  value = [
    for i in range(var.web_instance_count) : {
      name        = openstack_compute_instance_v2.web_servers[i].name
      private_ip  = openstack_compute_instance_v2.web_servers[i].access_ip_v4
      public_ip   = openstack_networking_floatingip_v2.web_fips[i].address
      ssh_command = "ssh -i terraform-key ubuntu@${openstack_networking_floatingip_v2.web_fips[i].address}"
      web_url     = "http://${openstack_networking_floatingip_v2.web_fips[i].address}"
    }
  ]
}

output "database_servers_info" {
  description = "Database servers information"
  value = [
    for i in range(var.database_instance_count) : {
      name       = openstack_compute_instance_v2.db_servers[i].name
      private_ip = openstack_compute_instance_v2.db_servers[i].access_ip_v4
      ssh_via_bastion = "ssh -i terraform-key -o ProxyCommand='ssh -i terraform-key -W %h:%p ubuntu@${openstack_networking_floatingip_v2.bastion_fip.address}' ubuntu@${openstack_compute_instance_v2.db_servers[i].access_ip_v4}"
    }
  ]
}

output "security_groups_info" {
  description = "Security groups configuration"
  value = {
    web_sg = {
      name  = openstack_networking_secgroup_v2.web_sg.name
      rules = length(openstack_networking_secgroup_v2.web_sg.rules)
    }
    db_sg = {
      name  = openstack_networking_secgroup_v2.db_sg.name
      rules = length(openstack_networking_secgroup_v2.db_sg.rules)
    }
    bastion_sg = {
      name  = openstack_networking_secgroup_v2.bastion_sg.name
      rules = length(openstack_networking_secgroup_v2.bastion_sg.rules)
    }
  }
}

output "connection_examples" {
  description = "Example connection commands"
  value = {
    direct_web_access    = "curl http://${openstack_networking_floatingip_v2.web_fips[0].address}"
    bastion_ssh          = "ssh -i terraform-key ubuntu@${openstack_networking_floatingip_v2.bastion_fip.address}"
    web_via_bastion      = "ssh -i terraform-key -o ProxyCommand='ssh -i terraform-key -W %h:%p ubuntu@${openstack_networking_floatingip_v2.bastion_fip.address}' ubuntu@${openstack_compute_instance_v2.web_servers[0].access_ip_v4}"
    db_via_bastion       = "ssh -i terraform-key -o ProxyCommand='ssh -i terraform-key -W %h:%p ubuntu@${openstack_networking_floatingip_v2.bastion_fip.address}' ubuntu@${openstack_compute_instance_v2.db_servers[0].access_ip_v4}"
    network_test_command = "ping -c 3 ${openstack_compute_instance_v2.db_servers[0].access_ip_v4}"
  }
}