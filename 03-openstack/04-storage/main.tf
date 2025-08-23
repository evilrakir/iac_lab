# OpenStack Storage and Volumes
# This exercise demonstrates persistent storage, volume management, and backup strategies

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
  default     = "terraform-storage"
}

variable "storage_servers_count" {
  description = "Number of storage server instances"
  type        = number
  default     = 2
}

variable "data_volume_size" {
  description = "Size of data volumes in GB"
  type        = number
  default     = 20
}

variable "backup_volume_size" {
  description = "Size of backup volumes in GB"
  type        = number
  default     = 50
}

# Data sources
data "openstack_images_image_v2" "ubuntu" {
  name        = "Ubuntu 22.04"
  most_recent = true
}

data "openstack_compute_flavor_v2" "medium" {
  name = "m1.medium"
}

data "openstack_networking_network_v2" "external" {
  name     = "external"
  external = true
}

data "openstack_networking_network_v2" "internal" {
  name = "internal"
}

# Create volumes for persistent data storage
resource "openstack_blockstorage_volume_v3" "data_volumes" {
  count = var.storage_servers_count
  
  name        = "${var.project_name}-data-${count.index + 1}"
  description = "Data volume for storage server ${count.index + 1}"
  size        = var.data_volume_size
  volume_type = "default"
  
  metadata = {
    created_by = "terraform"
    purpose    = "data_storage"
    server_id  = count.index + 1
  }
  
  tags = ["terraform", "storage", "data"]
}

# Create backup volumes
resource "openstack_blockstorage_volume_v3" "backup_volumes" {
  count = var.storage_servers_count
  
  name        = "${var.project_name}-backup-${count.index + 1}"
  description = "Backup volume for storage server ${count.index + 1}"
  size        = var.backup_volume_size
  volume_type = "default"
  
  metadata = {
    created_by = "terraform"
    purpose    = "backup_storage"
    server_id  = count.index + 1
  }
  
  tags = ["terraform", "storage", "backup"]
}

# Create shared volume for distributed storage
resource "openstack_blockstorage_volume_v3" "shared_volume" {
  name        = "${var.project_name}-shared"
  description = "Shared volume for distributed storage demonstration"
  size        = var.data_volume_size * 2
  volume_type = "default"
  
  metadata = {
    created_by = "terraform"
    purpose    = "shared_storage"
    shared     = "true"
  }
  
  tags = ["terraform", "storage", "shared"]
}

# Security group for storage servers
resource "openstack_networking_secgroup_v2" "storage_sg" {
  name        = "${var.project_name}-storage-sg"
  description = "Security group for storage servers"
  
  tags = ["terraform", "storage", "security"]
}

# SSH access
resource "openstack_networking_secgroup_rule_v2" "storage_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.storage_sg.id
  description       = "Allow SSH access"
}

# HTTP for monitoring dashboard
resource "openstack_networking_secgroup_rule_v2" "storage_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.storage_sg.id
  description       = "Allow HTTP for monitoring"
}

# NFS (if using network storage)
resource "openstack_networking_secgroup_rule_v2" "storage_nfs" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2049
  port_range_max    = 2049
  remote_group_id   = openstack_networking_secgroup_v2.storage_sg.id
  security_group_id = openstack_networking_secgroup_v2.storage_sg.id
  description       = "Allow NFS between storage servers"
}

# iSCSI (if using block storage)
resource "openstack_networking_secgroup_rule_v2" "storage_iscsi" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3260
  port_range_max    = 3260
  remote_group_id   = openstack_networking_secgroup_v2.storage_sg.id
  security_group_id = openstack_networking_secgroup_v2.storage_sg.id
  description       = "Allow iSCSI between storage servers"
}

# ICMP
resource "openstack_networking_secgroup_rule_v2" "storage_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.storage_sg.id
  description       = "Allow ICMP"
}

# Key pair for storage servers
resource "openstack_compute_keypair_v2" "storage_keypair" {
  name       = "${var.project_name}-keypair"
  public_key = file("${path.module}/terraform-key.pub")
}

# Storage server instances
resource "openstack_compute_instance_v2" "storage_servers" {
  count           = var.storage_servers_count
  name            = "${var.project_name}-server-${count.index + 1}"
  image_id        = data.openstack_images_image_v2.ubuntu.id
  flavor_id       = data.openstack_compute_flavor_v2.medium.id
  key_pair        = openstack_compute_keypair_v2.storage_keypair.name
  security_groups = [openstack_networking_secgroup_v2.storage_sg.name]

  network {
    uuid = data.openstack_networking_network_v2.internal.id
  }

  user_data = base64encode(templatefile("${path.module}/storage-user-data.sh", {
    hostname     = "${var.project_name}-server-${count.index + 1}"
    server_id    = count.index + 1
    project_name = var.project_name
  }))

  metadata = {
    role       = "storage"
    created_by = "terraform"
    lab        = "storage"
    server_id  = count.index + 1
  }

  tags = ["terraform", "storage", "server"]
}

# Attach data volumes to storage servers
resource "openstack_compute_volume_attach_v2" "data_volume_attachments" {
  count       = var.storage_servers_count
  instance_id = openstack_compute_instance_v2.storage_servers[count.index].id
  volume_id   = openstack_blockstorage_volume_v3.data_volumes[count.index].id
  device      = "/dev/vdb"
  
  # Ensure volume is created before attachment
  depends_on = [
    openstack_blockstorage_volume_v3.data_volumes,
    openstack_compute_instance_v2.storage_servers
  ]
}

# Attach backup volumes to storage servers
resource "openstack_compute_volume_attach_v2" "backup_volume_attachments" {
  count       = var.storage_servers_count
  instance_id = openstack_compute_instance_v2.storage_servers[count.index].id
  volume_id   = openstack_blockstorage_volume_v3.backup_volumes[count.index].id
  device      = "/dev/vdc"
  
  depends_on = [
    openstack_blockstorage_volume_v3.backup_volumes,
    openstack_compute_instance_v2.storage_servers
  ]
}

# Attach shared volume to first storage server
resource "openstack_compute_volume_attach_v2" "shared_volume_attachment" {
  instance_id = openstack_compute_instance_v2.storage_servers[0].id
  volume_id   = openstack_blockstorage_volume_v3.shared_volume.id
  device      = "/dev/vdd"
  
  depends_on = [
    openstack_blockstorage_volume_v3.shared_volume,
    openstack_compute_instance_v2.storage_servers
  ]
}

# Floating IPs for storage servers
resource "openstack_networking_floatingip_v2" "storage_fips" {
  count = var.storage_servers_count
  pool  = data.openstack_networking_network_v2.external.name
  tags  = ["terraform", "storage", "server-${count.index + 1}"]
}

# Associate floating IPs
resource "openstack_compute_floatingip_associate_v2" "storage_fip_associate" {
  count       = var.storage_servers_count
  floating_ip = openstack_networking_floatingip_v2.storage_fips[count.index].address
  instance_id = openstack_compute_instance_v2.storage_servers[count.index].id
}

# Create volume snapshots for backup demonstration
resource "openstack_blockstorage_volume_v3" "volume_snapshots" {
  count           = var.storage_servers_count
  name            = "${var.project_name}-snapshot-${count.index + 1}"
  description     = "Snapshot of data volume ${count.index + 1}"
  source_vol_id   = openstack_blockstorage_volume_v3.data_volumes[count.index].id
  size            = var.data_volume_size
  
  metadata = {
    created_by = "terraform"
    purpose    = "snapshot"
    source_volume = openstack_blockstorage_volume_v3.data_volumes[count.index].name
  }
  
  tags = ["terraform", "storage", "snapshot"]
  
  # Create snapshots after volumes are attached and configured
  depends_on = [openstack_compute_volume_attach_v2.data_volume_attachments]
}

# Outputs
output "storage_servers_info" {
  description = "Storage servers information"
  value = [
    for i in range(var.storage_servers_count) : {
      name        = openstack_compute_instance_v2.storage_servers[i].name
      private_ip  = openstack_compute_instance_v2.storage_servers[i].access_ip_v4
      public_ip   = openstack_networking_floatingip_v2.storage_fips[i].address
      ssh_command = "ssh -i terraform-key ubuntu@${openstack_networking_floatingip_v2.storage_fips[i].address}"
      web_url     = "http://${openstack_networking_floatingip_v2.storage_fips[i].address}"
    }
  ]
}

output "volumes_info" {
  description = "Volume information"
  value = {
    data_volumes = [
      for i in range(var.storage_servers_count) : {
        name        = openstack_blockstorage_volume_v3.data_volumes[i].name
        id          = openstack_blockstorage_volume_v3.data_volumes[i].id
        size        = openstack_blockstorage_volume_v3.data_volumes[i].size
        attached_to = openstack_compute_instance_v2.storage_servers[i].name
        device      = "/dev/vdb"
      }
    ]
    backup_volumes = [
      for i in range(var.storage_servers_count) : {
        name        = openstack_blockstorage_volume_v3.backup_volumes[i].name
        id          = openstack_blockstorage_volume_v3.backup_volumes[i].id
        size        = openstack_blockstorage_volume_v3.backup_volumes[i].size
        attached_to = openstack_compute_instance_v2.storage_servers[i].name
        device      = "/dev/vdc"
      }
    ]
    shared_volume = {
      name        = openstack_blockstorage_volume_v3.shared_volume.name
      id          = openstack_blockstorage_volume_v3.shared_volume.id
      size        = openstack_blockstorage_volume_v3.shared_volume.size
      attached_to = openstack_compute_instance_v2.storage_servers[0].name
      device      = "/dev/vdd"
    }
  }
}

output "snapshots_info" {
  description = "Volume snapshots information"
  value = [
    for i in range(var.storage_servers_count) : {
      name        = openstack_blockstorage_volume_v3.volume_snapshots[i].name
      id          = openstack_blockstorage_volume_v3.volume_snapshots[i].id
      size        = openstack_blockstorage_volume_v3.volume_snapshots[i].size
      source      = openstack_blockstorage_volume_v3.data_volumes[i].name
    }
  ]
}

output "storage_commands" {
  description = "Useful storage management commands"
  value = {
    check_volumes     = "lsblk"
    check_mounts      = "df -h"
    check_filesystems = "sudo fdisk -l"
    monitor_io        = "sudo iotop"
    test_performance  = "sudo fio --name=test --size=1G --rw=randwrite --bs=4k --numjobs=1 --time_based --runtime=30s --filename=/data/test.fio"
  }
}

output "connection_examples" {
  description = "Example connection and management commands"
  value = {
    ssh_to_server_1 = "ssh -i terraform-key ubuntu@${openstack_networking_floatingip_v2.storage_fips[0].address}"
    view_dashboard  = "http://${openstack_networking_floatingip_v2.storage_fips[0].address}"
    check_storage   = "ssh -i terraform-key ubuntu@${openstack_networking_floatingip_v2.storage_fips[0].address} 'sudo df -h'"
    performance_test = "ssh -i terraform-key ubuntu@${openstack_networking_floatingip_v2.storage_fips[0].address} 'sudo /opt/storage-tools/benchmark.sh'"
  }
}