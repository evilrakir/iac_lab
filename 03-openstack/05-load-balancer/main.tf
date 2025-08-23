# OpenStack Load Balancer and High Availability
# This exercise demonstrates load balancing, health checks, and HA configuration

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
  default     = "terraform-lb"
}

variable "web_servers_count" {
  description = "Number of web server instances"
  type        = number
  default     = 3
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

data "openstack_networking_network_v2" "internal" {
  name = "internal"
}

# Create network for load balancer
resource "openstack_networking_network_v2" "lb_network" {
  name           = "${var.project_name}-network"
  admin_state_up = "true"
  tags = ["terraform", "load-balancer"]
}

resource "openstack_networking_subnet_v2" "lb_subnet" {
  name       = "${var.project_name}-subnet"
  network_id = openstack_networking_network_v2.lb_network.id
  cidr       = "192.168.100.0/24"
  ip_version = 4
  
  allocation_pool {
    start = "192.168.100.10"
    end   = "192.168.100.200"
  }
  
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Create router
resource "openstack_networking_router_v2" "lb_router" {
  name                = "${var.project_name}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "lb_interface" {
  router_id = openstack_networking_router_v2.lb_router.id
  subnet_id = openstack_networking_subnet_v2.lb_subnet.id
}

# Security group for load balancer
resource "openstack_networking_secgroup_v2" "lb_sg" {
  name        = "${var.project_name}-lb-sg"
  description = "Security group for load balancer"
}

# Load balancer HTTP/HTTPS access
resource "openstack_networking_secgroup_rule_v2" "lb_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.lb_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "lb_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.lb_sg.id
}

# Security group for web servers
resource "openstack_networking_secgroup_v2" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web servers behind load balancer"
}

resource "openstack_networking_secgroup_rule_v2" "web_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "web_http_from_lb" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_group_id   = openstack_networking_secgroup_v2.lb_sg.id
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "web_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
}

# Key pair
resource "openstack_compute_keypair_v2" "lb_keypair" {
  name       = "${var.project_name}-keypair"
  public_key = file("${path.module}/terraform-key.pub")
}

# Web server instances
resource "openstack_compute_instance_v2" "web_servers" {
  count           = var.web_servers_count
  name            = "${var.project_name}-web-${count.index + 1}"
  image_id        = data.openstack_images_image_v2.ubuntu.id
  flavor_id       = data.openstack_compute_flavor_v2.small.id
  key_pair        = openstack_compute_keypair_v2.lb_keypair.name
  security_groups = [openstack_networking_secgroup_v2.web_sg.name]

  network {
    uuid = openstack_networking_network_v2.lb_network.id
  }

  user_data = base64encode(templatefile("${path.module}/web-server-user-data.sh", {
    hostname     = "${var.project_name}-web-${count.index + 1}"
    server_id    = count.index + 1
    project_name = var.project_name
  }))

  metadata = {
    role       = "web"
    created_by = "terraform"
    lab        = "load-balancer"
  }

  tags = ["terraform", "web", "load-balanced"]
}

# Load balancer
resource "openstack_lb_loadbalancer_v2" "main_lb" {
  name          = "${var.project_name}-loadbalancer"
  vip_subnet_id = openstack_networking_subnet_v2.lb_subnet.id
  
  tags = ["terraform", "load-balancer"]
  
  depends_on = [openstack_networking_subnet_v2.lb_subnet]
}

# Load balancer listener
resource "openstack_lb_listener_v2" "http_listener" {
  name            = "${var.project_name}-http-listener"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.main_lb.id
}

# Load balancer pool
resource "openstack_lb_pool_v2" "web_pool" {
  name        = "${var.project_name}-web-pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.http_listener.id
}

# Health monitor
resource "openstack_lb_monitor_v2" "health_monitor" {
  name        = "${var.project_name}-health-monitor"
  type        = "HTTP"
  delay       = 5
  timeout     = 3
  max_retries = 3
  url_path    = "/health"
  pool_id     = openstack_lb_pool_v2.web_pool.id
}

# Pool members (web servers)
resource "openstack_lb_member_v2" "web_members" {
  count         = var.web_servers_count
  name          = "${var.project_name}-member-${count.index + 1}"
  address       = openstack_compute_instance_v2.web_servers[count.index].access_ip_v4
  protocol_port = 80
  pool_id       = openstack_lb_pool_v2.web_pool.id
  subnet_id     = openstack_networking_subnet_v2.lb_subnet.id
  
  depends_on = [openstack_compute_instance_v2.web_servers]
}

# Floating IP for load balancer
resource "openstack_networking_floatingip_v2" "lb_fip" {
  pool = data.openstack_networking_network_v2.external.name
  tags = ["terraform", "load-balancer"]
}

# Associate floating IP with load balancer VIP
resource "openstack_networking_floatingip_associate_v2" "lb_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.lb_fip.address
  port_id     = openstack_lb_loadbalancer_v2.main_lb.vip_port_id
}

# Outputs
output "load_balancer_info" {
  description = "Load balancer information"
  value = {
    name       = openstack_lb_loadbalancer_v2.main_lb.name
    vip_address = openstack_lb_loadbalancer_v2.main_lb.vip_address
    public_ip  = openstack_networking_floatingip_v2.lb_fip.address
    url        = "http://${openstack_networking_floatingip_v2.lb_fip.address}"
  }
}

output "web_servers_info" {
  description = "Web servers behind load balancer"
  value = [
    for i in range(var.web_servers_count) : {
      name       = openstack_compute_instance_v2.web_servers[i].name
      private_ip = openstack_compute_instance_v2.web_servers[i].access_ip_v4
      health_url = "http://${openstack_compute_instance_v2.web_servers[i].access_ip_v4}/health"
    }
  ]
}

output "testing_commands" {
  description = "Commands to test load balancer functionality"
  value = {
    test_load_balancer = "curl http://${openstack_networking_floatingip_v2.lb_fip.address}"
    test_multiple_requests = "for i in {1..10}; do curl -s http://${openstack_networking_floatingip_v2.lb_fip.address} | grep 'Server ID'; done"
    test_health_check = "curl http://${openstack_networking_floatingip_v2.lb_fip.address}/health"
    monitor_pool_status = "watch -n 2 'curl -s http://${openstack_networking_floatingip_v2.lb_fip.address}/lb-status'"
  }
}