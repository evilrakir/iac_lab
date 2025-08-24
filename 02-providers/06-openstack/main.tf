# Exercise: OpenStack Provider - Private Cloud Infrastructure
# Learn to manage OpenStack resources with Terraform

terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

# ========================================================================
# SECTION 1: PROVIDER CONFIGURATION
# ========================================================================

# OpenStack provider configuration
# In production, use environment variables or clouds.yaml
provider "openstack" {
  # Authentication options (use environment variables in production)
  # auth_url    = "http://myopenstack.local:5000/v3"
  # user_name   = "admin"
  # password    = "admin_password"
  # tenant_name = "admin"
  # domain_name = "Default"
  # region      = "RegionOne"
  
  # For this lab, we'll use mock configuration
  # In real environments, set OS_* environment variables:
  # OS_AUTH_URL, OS_USERNAME, OS_PASSWORD, OS_PROJECT_NAME, etc.
}

# ========================================================================
# SECTION 2: VARIABLES FOR OPENSTACK RESOURCES
# ========================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "openstack-lab"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "development"
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 2
}

variable "flavor_name" {
  description = "OpenStack flavor (instance type)"
  type        = string
  default     = "m1.small"
  
  # Common flavors: m1.tiny, m1.small, m1.medium, m1.large, m1.xlarge
}

variable "image_name" {
  description = "OpenStack image name"
  type        = string
  default     = "Ubuntu-22.04"
  
  # Common images: Ubuntu-22.04, CentOS-8, Windows-Server-2022
}

variable "network_cidr" {
  description = "CIDR block for the network"
  type        = string
  default     = "10.0.0.0/24"
}

variable "dns_servers" {
  description = "DNS servers for the subnet"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "enable_floating_ip" {
  description = "Attach floating IPs to instances"
  type        = bool
  default     = true
}

variable "security_rules" {
  description = "Security group rules"
  type = list(object({
    direction        = string
    ethertype        = string
    protocol         = string
    port_range_min   = number
    port_range_max   = number
    remote_ip_prefix = string
  }))
  default = [
    {
      direction        = "ingress"
      ethertype        = "IPv4"
      protocol         = "tcp"
      port_range_min   = 22
      port_range_max   = 22
      remote_ip_prefix = "0.0.0.0/0"
    },
    {
      direction        = "ingress"
      ethertype        = "IPv4"
      protocol         = "tcp"
      port_range_min   = 80
      port_range_max   = 80
      remote_ip_prefix = "0.0.0.0/0"
    },
    {
      direction        = "ingress"
      ethertype        = "IPv4"
      protocol         = "tcp"
      port_range_min   = 443
      port_range_max   = 443
      remote_ip_prefix = "0.0.0.0/0"
    }
  ]
}

# ========================================================================
# SECTION 3: DATA SOURCES - DISCOVER EXISTING RESOURCES
# ========================================================================

# NOTE: These data sources would work with a real OpenStack deployment
# For the lab, they're commented out to avoid errors

# # Discover available images
# data "openstack_images_image_v2" "ubuntu" {
#   name        = var.image_name
#   most_recent = true
# }

# # Discover available flavors
# data "openstack_compute_flavor_v2" "small" {
#   name = var.flavor_name
# }

# # Discover external network for floating IPs
# data "openstack_networking_network_v2" "external" {
#   name     = "public"
#   external = true
# }

# ========================================================================
# SECTION 4: NETWORKING RESOURCES
# ========================================================================

# Create a network
# resource "openstack_networking_network_v2" "network" {
#   name           = "${var.project_name}-network"
#   admin_state_up = true
# }

# # Create a subnet
# resource "openstack_networking_subnet_v2" "subnet" {
#   name       = "${var.project_name}-subnet"
#   network_id = openstack_networking_network_v2.network.id
#   cidr       = var.network_cidr
#   ip_version = 4
#   dns_nameservers = var.dns_servers
#   
#   allocation_pool {
#     start = cidrhost(var.network_cidr, 10)
#     end   = cidrhost(var.network_cidr, 250)
#   }
# }

# # Create a router
# resource "openstack_networking_router_v2" "router" {
#   name                = "${var.project_name}-router"
#   admin_state_up      = true
#   external_network_id = data.openstack_networking_network_v2.external.id
# }

# # Connect subnet to router
# resource "openstack_networking_router_interface_v2" "router_interface" {
#   router_id = openstack_networking_router_v2.router.id
#   subnet_id = openstack_networking_subnet_v2.subnet.id
# }

# ========================================================================
# SECTION 5: SECURITY GROUPS
# ========================================================================

# # Create security group
# resource "openstack_networking_secgroup_v2" "secgroup" {
#   name        = "${var.project_name}-security-group"
#   description = "Security group for ${var.project_name}"
# }

# # Add security group rules
# resource "openstack_networking_secgroup_rule_v2" "secgroup_rules" {
#   for_each = {
#     for idx, rule in var.security_rules : 
#     "${rule.protocol}-${rule.port_range_min}" => rule
#   }
#   
#   direction         = each.value.direction
#   ethertype         = each.value.ethertype
#   protocol          = each.value.protocol
#   port_range_min    = each.value.port_range_min
#   port_range_max    = each.value.port_range_max
#   remote_ip_prefix  = each.value.remote_ip_prefix
#   security_group_id = openstack_networking_secgroup_v2.secgroup.id
# }

# ========================================================================
# SECTION 6: COMPUTE INSTANCES
# ========================================================================

# # Generate SSH key pair
# resource "openstack_compute_keypair_v2" "keypair" {
#   name = "${var.project_name}-keypair"
#   # In production, use file() to read existing public key
#   # public_key = file("~/.ssh/id_rsa.pub")
# }

# # Create compute instances
# resource "openstack_compute_instance_v2" "instances" {
#   count = var.instance_count
#   
#   name            = "${var.project_name}-instance-${count.index + 1}"
#   image_id        = data.openstack_images_image_v2.ubuntu.id
#   flavor_id       = data.openstack_compute_flavor_v2.small.id
#   key_pair        = openstack_compute_keypair_v2.keypair.name
#   security_groups = [openstack_networking_secgroup_v2.secgroup.name]
#   
#   metadata = {
#     environment = var.environment
#     managed_by  = "terraform"
#     index       = count.index
#   }
#   
#   network {
#     uuid = openstack_networking_network_v2.network.id
#   }
#   
#   # User data for cloud-init
#   user_data = <<-EOT
#     #cloud-config
#     package_update: true
#     packages:
#       - nginx
#       - docker.io
#     runcmd:
#       - systemctl start nginx
#       - systemctl enable nginx
#       - echo "Instance ${count.index + 1}" > /var/www/html/index.html
#   EOT
# }

# ========================================================================
# SECTION 7: FLOATING IPS
# ========================================================================

# # Allocate floating IPs
# resource "openstack_networking_floatingip_v2" "floating_ips" {
#   count = var.enable_floating_ip ? var.instance_count : 0
#   
#   pool = "public"
#   description = "Floating IP for ${var.project_name}-instance-${count.index + 1}"
# }

# # Associate floating IPs with instances
# resource "openstack_compute_floatingip_associate_v2" "floating_ip_assoc" {
#   count = var.enable_floating_ip ? var.instance_count : 0
#   
#   floating_ip = openstack_networking_floatingip_v2.floating_ips[count.index].address
#   instance_id = openstack_compute_instance_v2.instances[count.index].id
# }

# ========================================================================
# SECTION 8: BLOCK STORAGE (CINDER)
# ========================================================================

# # Create volumes
# resource "openstack_blockstorage_volume_v3" "volumes" {
#   count = var.instance_count
#   
#   name        = "${var.project_name}-volume-${count.index + 1}"
#   description = "Data volume for instance ${count.index + 1}"
#   size        = 10  # GB
#   
#   metadata = {
#     environment = var.environment
#     attached_to = "${var.project_name}-instance-${count.index + 1}"
#   }
# }

# # Attach volumes to instances
# resource "openstack_compute_volume_attach_v2" "volume_attachments" {
#   count = var.instance_count
#   
#   instance_id = openstack_compute_instance_v2.instances[count.index].id
#   volume_id   = openstack_blockstorage_volume_v3.volumes[count.index].id
# }

# ========================================================================
# SECTION 9: OBJECT STORAGE (SWIFT)
# ========================================================================

# # Create Swift container (bucket)
# resource "openstack_objectstorage_container_v1" "container" {
#   name   = "${var.project_name}-container"
#   
#   metadata = {
#     environment = var.environment
#     managed_by  = "terraform"
#   }
#   
#   # Container access control
#   container_read  = ".r:*,.rlistings"  # Public read
#   container_write = ""                  # Private write
# }

# # Upload object to container
# resource "openstack_objectstorage_object_v1" "config_object" {
#   container_name = openstack_objectstorage_container_v1.container.name
#   name           = "config/app-config.json"
#   
#   content = jsonencode({
#     project     = var.project_name
#     environment = var.environment
#     instances   = var.instance_count
#     timestamp   = timestamp()
#   })
#   
#   content_type = "application/json"
# }

# ========================================================================
# SECTION 10: LOAD BALANCER (OCTAVIA)
# ========================================================================

# # Create load balancer
# resource "openstack_lb_loadbalancer_v2" "loadbalancer" {
#   name          = "${var.project_name}-lb"
#   vip_subnet_id = openstack_networking_subnet_v2.subnet.id
# }

# # Create listener
# resource "openstack_lb_listener_v2" "listener" {
#   name            = "${var.project_name}-listener"
#   protocol        = "HTTP"
#   protocol_port   = 80
#   loadbalancer_id = openstack_lb_loadbalancer_v2.loadbalancer.id
# }

# # Create pool
# resource "openstack_lb_pool_v2" "pool" {
#   name        = "${var.project_name}-pool"
#   protocol    = "HTTP"
#   lb_method   = "ROUND_ROBIN"
#   listener_id = openstack_lb_listener_v2.listener.id
# }

# # Add members to pool
# resource "openstack_lb_member_v2" "members" {
#   count = var.instance_count
#   
#   pool_id       = openstack_lb_pool_v2.pool.id
#   address       = openstack_compute_instance_v2.instances[count.index].access_ip_v4
#   protocol_port = 80
# }

# # Create health monitor
# resource "openstack_lb_monitor_v2" "monitor" {
#   pool_id        = openstack_lb_pool_v2.pool.id
#   type           = "HTTP"
#   delay          = 5
#   timeout        = 3
#   max_retries    = 3
#   url_path       = "/"
#   expected_codes = "200"
# }

# ========================================================================
# SECTION 11: LOCAL FILES FOR DOCUMENTATION
# ========================================================================

# Create local configuration documentation
resource "local_file" "openstack_config" {
  filename = "${path.module}/output/openstack-config.yaml"
  content = yamlencode({
    provider_info = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
      docs    = "https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs"
    }
    
    project_config = {
      name           = var.project_name
      environment    = var.environment
      instance_count = var.instance_count
      flavor         = var.flavor_name
      image          = var.image_name
      network_cidr   = var.network_cidr
    }
    
    resources_to_create = {
      networking = {
        networks        = 1
        subnets         = 1
        routers         = 1
        security_groups = 1
        floating_ips    = var.enable_floating_ip ? var.instance_count : 0
      }
      compute = {
        instances = var.instance_count
        keypairs  = 1
      }
      storage = {
        volumes    = var.instance_count
        containers = 1
        objects    = 1
      }
      load_balancing = {
        load_balancers = 1
        listeners      = 1
        pools          = 1
        members        = var.instance_count
        monitors       = 1
      }
    }
    
    authentication_methods = {
      environment_variables = [
        "OS_AUTH_URL",
        "OS_USERNAME",
        "OS_PASSWORD",
        "OS_PROJECT_NAME",
        "OS_USER_DOMAIN_NAME",
        "OS_PROJECT_DOMAIN_NAME",
        "OS_REGION_NAME"
      ]
      clouds_yaml = "~/.config/openstack/clouds.yaml"
      direct_config = "provider block attributes"
    }
    
    common_operations = {
      list_servers   = "openstack server list"
      list_networks  = "openstack network list"
      list_images    = "openstack image list"
      list_flavors   = "openstack flavor list"
      list_volumes   = "openstack volume list"
    }
  })
}

# Create PowerShell comparison guide
resource "local_file" "powershell_comparison" {
  filename = "${path.module}/output/powershell-to-openstack.md"
  content = <<-EOT
    # PowerShell to OpenStack Terraform Comparison
    
    ## Virtual Machine Management
    
    ### PowerShell (Hyper-V)
    ```powershell
    New-VM -Name "TestVM" -MemoryStartupBytes 2GB -VHDPath "C:\VMs\test.vhdx"
    Start-VM -Name "TestVM"
    ```
    
    ### OpenStack Terraform
    ```hcl
    resource "openstack_compute_instance_v2" "vm" {
      name      = "TestVM"
      flavor_id = "2"  # 2GB RAM flavor
      image_id  = "ubuntu-22.04"
    }
    ```
    
    ## Network Management
    
    ### PowerShell (Hyper-V)
    ```powershell
    New-VMSwitch -Name "Internal" -SwitchType Internal
    New-NetIPAddress -IPAddress 10.0.0.1 -PrefixLength 24
    ```
    
    ### OpenStack Terraform
    ```hcl
    resource "openstack_networking_network_v2" "network" {
      name = "Internal"
    }
    
    resource "openstack_networking_subnet_v2" "subnet" {
      network_id = openstack_networking_network_v2.network.id
      cidr       = "10.0.0.0/24"
    }
    ```
    
    ## Storage Management
    
    ### PowerShell
    ```powershell
    New-VHD -Path "C:\VMs\data.vhdx" -SizeBytes 10GB
    Add-VMHardDiskDrive -VMName "TestVM" -Path "C:\VMs\data.vhdx"
    ```
    
    ### OpenStack Terraform
    ```hcl
    resource "openstack_blockstorage_volume_v3" "volume" {
      name = "data"
      size = 10
    }
    
    resource "openstack_compute_volume_attach_v2" "attach" {
      instance_id = openstack_compute_instance_v2.vm.id
      volume_id   = openstack_blockstorage_volume_v3.volume.id
    }
    ```
    
    ## Security Groups (Firewall)
    
    ### PowerShell
    ```powershell
    New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
    ```
    
    ### OpenStack Terraform
    ```hcl
    resource "openstack_networking_secgroup_rule_v2" "http" {
      direction        = "ingress"
      protocol         = "tcp"
      port_range_min   = 80
      port_range_max   = 80
      remote_ip_prefix = "0.0.0.0/0"
      security_group_id = openstack_networking_secgroup_v2.secgroup.id
    }
    ```
    
    ## Key Concepts Mapping
    
    | PowerShell/Windows | OpenStack | Purpose |
    |--------------------|-----------|---------|
    | Hyper-V VM | Instance | Virtual machine |
    | Virtual Switch | Network | Virtual network |
    | VHDX | Volume | Block storage |
    | Windows Firewall | Security Group | Network access control |
    | Public IP | Floating IP | External connectivity |
    | NLB | Load Balancer | Traffic distribution |
    | Storage Spaces | Swift/Cinder | Object/Block storage |
    
    ## Environment Setup
    
    ### PowerShell Environment Variables
    ```powershell
    $env:OS_AUTH_URL = "http://openstack.local:5000/v3"
    $env:OS_USERNAME = "admin"
    $env:OS_PASSWORD = "password"
    $env:OS_PROJECT_NAME = "admin"
    ```
    
    ### Terraform Init and Apply
    ```bash
    terraform init
    terraform plan
    terraform apply
    ```
  EOT
}

# Create comprehensive learning guide
resource "local_file" "learning_guide" {
  filename = "${path.module}/output/OPENSTACK_GUIDE.md"
  content = <<-EOT
    # OpenStack with Terraform - Complete Learning Guide
    
    ## What is OpenStack?
    
    OpenStack is an open-source cloud computing platform that provides:
    - **IaaS (Infrastructure as a Service)**: Virtual machines, networks, storage
    - **Private Cloud**: Run your own AWS-like environment
    - **Multi-tenancy**: Multiple projects/users with isolation
    - **API-driven**: Everything is programmable
    
    ## OpenStack Components
    
    ### Core Services
    1. **Nova** (Compute): Manages virtual machines
    2. **Neutron** (Networking): Virtual networks, subnets, routers
    3. **Cinder** (Block Storage): Persistent volumes
    4. **Swift** (Object Storage): S3-like object storage
    5. **Keystone** (Identity): Authentication and authorization
    6. **Glance** (Images): VM image management
    7. **Horizon** (Dashboard): Web UI
    
    ### Additional Services
    - **Octavia**: Load balancing
    - **Heat**: Orchestration (like CloudFormation)
    - **Designate**: DNS as a Service
    - **Barbican**: Key management
    - **Magnum**: Container orchestration
    
    ## Why OpenStack for Enterprises?
    
    1. **No Vendor Lock-in**: Open source, runs anywhere
    2. **Cost Control**: No cloud bills, predictable costs
    3. **Data Sovereignty**: Keep data on-premise
    4. **Customization**: Modify to meet specific needs
    5. **Integration**: Works with existing infrastructure
    
    ## Common Use Cases
    
    ### Development/Testing
    - Spin up environments on-demand
    - Test infrastructure changes safely
    - Replicate production environments
    
    ### Private Cloud
    - Replace VMware with open source
    - Build internal cloud platform
    - Provide self-service to developers
    
    ### Hybrid Cloud
    - Burst to public cloud when needed
    - Keep sensitive data on-premise
    - Disaster recovery across clouds
    
    ## Terraform + OpenStack Benefits
    
    1. **Infrastructure as Code**: Version control your cloud
    2. **Consistency**: Same config across environments
    3. **Automation**: No manual clicking in Horizon
    4. **Documentation**: Code is documentation
    5. **Disaster Recovery**: Rebuild from code
    
    ## Setting Up OpenStack (DevStack)
    
    For learning, use DevStack (single-node OpenStack):
    
    ```bash
    # On Ubuntu 22.04
    git clone https://opendev.org/openstack/devstack
    cd devstack
    
    # Create local.conf
    cat > local.conf <<EOF
    [[local|localrc]]
    ADMIN_PASSWORD=secret
    DATABASE_PASSWORD=secret
    RABBIT_PASSWORD=secret
    SERVICE_PASSWORD=secret
    HOST_IP=10.0.0.10
    EOF
    
    # Install (takes ~30 minutes)
    ./stack.sh
    ```
    
    ## Authentication Setup
    
    ### Option 1: Environment Variables
    ```bash
    export OS_AUTH_URL=http://10.0.0.10/identity/v3
    export OS_PROJECT_NAME=demo
    export OS_USERNAME=admin
    export OS_PASSWORD=secret
    export OS_USER_DOMAIN_NAME=Default
    export OS_PROJECT_DOMAIN_NAME=Default
    export OS_REGION_NAME=RegionOne
    ```
    
    ### Option 2: clouds.yaml
    ```yaml
    clouds:
      mycloud:
        auth:
          auth_url: http://10.0.0.10/identity/v3
          username: admin
          password: secret
          project_name: demo
          user_domain_name: Default
          project_domain_name: Default
        region_name: RegionOne
    ```
    
    ## Essential OpenStack Commands
    
    ```bash
    # List resources
    openstack server list
    openstack network list
    openstack volume list
    openstack image list
    openstack flavor list
    
    # Create instance
    openstack server create --image Ubuntu --flavor m1.small myserver
    
    # Networking
    openstack network create mynet
    openstack subnet create --network mynet --subnet-range 10.0.0.0/24 mysubnet
    
    # Storage
    openstack volume create --size 10 myvolume
    openstack server add volume myserver myvolume
    ```
    
    ## Terraform Workflow with OpenStack
    
    1. **Initialize Provider**
       ```bash
       terraform init
       ```
    
    2. **Plan Infrastructure**
       ```bash
       terraform plan
       ```
    
    3. **Apply Changes**
       ```bash
       terraform apply
       ```
    
    4. **View State**
       ```bash
       terraform show
       ```
    
    5. **Destroy Resources**
       ```bash
       terraform destroy
       ```
    
    ## Best Practices
    
    1. **Use Data Sources**: Discover existing resources
    2. **Tag Everything**: Use metadata for organization
    3. **Security Groups**: Define before instances
    4. **Key Management**: Use existing SSH keys
    5. **Network Planning**: Design network topology first
    6. **State Management**: Use remote state for teams
    7. **Module Usage**: Create reusable modules
    
    ## Troubleshooting
    
    ### Authentication Issues
    - Verify OS_* environment variables
    - Check auth_url includes /v3 for Keystone v3
    - Ensure project and domain names are correct
    
    ### Network Issues
    - Verify security group rules
    - Check router has external gateway
    - Ensure floating IP pool exists
    
    ### Resource Limits
    - Check quotas: `openstack quota show`
    - Verify available resources
    - Check flavor requirements
    
    ## Next Steps
    
    1. Set up DevStack or access existing OpenStack
    2. Configure authentication
    3. Run terraform init
    4. Uncomment resources in main.tf
    5. Create your infrastructure!
    
    ## Additional Resources
    
    - [OpenStack Docs](https://docs.openstack.org)
    - [Terraform OpenStack Provider](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs)
    - [DevStack Quick Start](https://docs.openstack.org/devstack/latest/)
    - [OpenStack CLI Reference](https://docs.openstack.org/python-openstackclient/latest/cli/command-list.html)
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "openstack_summary" {
  description = "Summary of OpenStack configuration"
  value = {
    project = {
      name        = var.project_name
      environment = var.environment
    }
    
    compute = {
      instances = var.instance_count
      flavor    = var.flavor_name
      image     = var.image_name
    }
    
    networking = {
      cidr         = var.network_cidr
      floating_ips = var.enable_floating_ip
    }
    
    configuration_files = {
      config_doc   = local_file.openstack_config.filename
      ps_guide     = local_file.powershell_comparison.filename
      learn_guide  = local_file.learning_guide.filename
    }
  }
}

output "next_steps" {
  description = "Next steps to use this configuration"
  value = <<-EOT
    
    TO USE THIS CONFIGURATION WITH REAL OPENSTACK:
    
    1. Set up authentication:
       export OS_AUTH_URL="http://your-openstack:5000/v3"
       export OS_USERNAME="your-username"
       export OS_PASSWORD="your-password"
       export OS_PROJECT_NAME="your-project"
       export OS_USER_DOMAIN_NAME="Default"
       export OS_PROJECT_DOMAIN_NAME="Default"
    
    2. Uncomment the resource blocks in main.tf
    
    3. Run Terraform:
       terraform init
       terraform plan
       terraform apply
    
    4. View created resources:
       terraform show
       openstack server list
    
    Note: This lab file has resources commented out to avoid errors
    without a real OpenStack environment. The local files still create
    to provide learning documentation.
    
  EOT
}