# Exercise 3: Advanced Networking and Security Groups

## Learning Objectives

In this exercise, you will:
- Create a custom network topology with multiple subnets
- Configure advanced security groups with tier-based access control
- Deploy a multi-tier application architecture (web, database, bastion)
- Implement network segmentation and security best practices
- Set up a bastion host for secure private network access
- Configure load balancer concepts with multiple web servers

## Prerequisites

- Completed Exercise 1 (OpenStack Provider Setup)
- Completed Exercise 2 (Basic VM Deployment)
- SSH key pair available (terraform-key)
- Understanding of network concepts (subnets, routing, security groups)

## Architecture Overview

This exercise creates a secure, multi-tier network architecture:

```
Internet
    |
    v
[Router] ←→ External Network
    |
    ├── Web Subnet (10.0.1.0/24)
    │   ├── Bastion Host (10.0.1.10) [Public IP]
    │   ├── Web Server 1 (10.0.1.x) [Public IP]
    │   └── Web Server 2 (10.0.1.x) [Public IP]
    │
    └── Database Subnet (10.0.2.0/24)
        └── Database Server (10.0.2.x) [Private only]
```

## Security Model

### Network Segmentation
- **Web Subnet**: Internet-facing services with public IPs
- **Database Subnet**: Private backend services, no direct internet access
- **Bastion Host**: Secure jump server for administrative access

### Security Group Rules
- **Web SG**: SSH (22), HTTP (80), HTTPS (443) from internet
- **Database SG**: SSH from web subnet only, MySQL/PostgreSQL from web servers
- **Bastion SG**: SSH from internet, acts as gateway to private networks

## What You'll Create

### Network Infrastructure
- 🌐 **Custom Private Network** - Isolated network environment
- 🔀 **Router** - Connected to external network for internet access
- 🏠 **Web Subnet** - Frontend services (10.0.1.0/24)
- 🔒 **Database Subnet** - Backend services (10.0.2.0/24)

### Security Groups
- 🛡️ **Web Security Group** - Internet-facing rules
- 🔐 **Database Security Group** - Restricted backend access
- 🚪 **Bastion Security Group** - Jump server access

### Virtual Machines
- 🖥️ **Bastion Host** - Secure access point with monitoring tools
- 🌐 **Web Servers (2)** - Load-balanced application servers
- 🗄️ **Database Server** - MySQL, PostgreSQL, Redis, Memcached

### Features
- ⚡ **Floating IPs** - External access for web tier and bastion
- 🔑 **SSH Key Management** - Secure authentication
- 📊 **Monitoring Dashboards** - Web interfaces for each tier
- 🔄 **Automated Configuration** - User-data scripts for all services

## Quick Start

### 1. Prepare SSH Keys

If you haven't created SSH keys yet:
```bash
ssh-keygen -t rsa -b 4096 -f terraform-key -N ""
```

### 2. Initialize and Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Access Your Infrastructure

After deployment, use the connection information from outputs:

```bash
# View all connection details
terraform output

# Connect to bastion host
ssh -i terraform-key ubuntu@<bastion-public-ip>

# Access web servers directly
curl http://<web-server-public-ip>

# Access database via bastion (SSH tunnel)
ssh -i terraform-key -L 3306:10.0.2.20:3306 ubuntu@<bastion-ip>
```

## Testing Network Connectivity

### 1. Direct Web Access
```bash
# Test web servers
curl http://<web-server-1-ip>
curl http://<web-server-2-ip>

# Each should show a different server ID
```

### 2. Bastion Host Access
```bash
# Connect to bastion
ssh -i terraform-key ubuntu@<bastion-ip>

# From bastion, scan the network
sudo /opt/bastion-tools/network-scan.sh

# Test connectivity to other servers
sudo /opt/bastion-tools/connectivity-test.sh
```

### 3. Database Access via Bastion
```bash
# SSH to database server via bastion
ssh -i terraform-key -o ProxyCommand='ssh -i terraform-key -W %h:%p ubuntu@<bastion-ip>' ubuntu@<db-server-ip>

# MySQL tunnel via bastion
ssh -i terraform-key -L 3306:<db-server-ip>:3306 ubuntu@<bastion-ip>
# Then connect: mysql -h localhost -u webapp -p
```

### 4. Security Testing
```bash
# Try direct SSH to database (should fail)
ssh -i terraform-key ubuntu@<db-server-private-ip>

# Try database connection from outside (should fail)
mysql -h <db-server-private-ip> -u webapp -p
```

## Understanding the Configuration

### Custom Network Creation
```hcl
resource "openstack_networking_network_v2" "private_network" {
  name           = "${var.project_name}-network"
  admin_state_up = "true"
  tags = ["terraform", "lab", "networking"]
}
```

Creates an isolated network environment separate from default networks.

### Subnet Configuration
```hcl
resource "openstack_networking_subnet_v2" "web_subnet" {
  name       = "${var.project_name}-web-subnet"
  network_id = openstack_networking_network_v2.private_network.id
  cidr       = "10.0.1.0/24"
  # ... allocation pools and DNS
}
```

Defines IP ranges and configuration for each network tier.

### Security Group Rules
```hcl
resource "openstack_networking_secgroup_rule_v2" "db_mysql" {
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_group_id   = openstack_networking_secgroup_v2.web_sg.id
  security_group_id = openstack_networking_secgroup_v2.db_sg.id
}
```

Allows MySQL access only from web security group members.

### Router and External Connectivity
```hcl
resource "openstack_networking_router_v2" "router" {
  name                = "${var.project_name}-router"
  external_network_id = data.openstack_networking_network_v2.external.id
}
```

Provides internet connectivity while maintaining network isolation.

## Monitoring and Dashboards

Each server tier includes a web dashboard:

### Bastion Dashboard
- Network scanning tools
- Connectivity testing
- Security monitoring
- Connection examples

### Web Server Dashboard  
- Load balancer identification
- Application metrics
- Database connectivity status
- Performance monitoring

### Database Dashboard
- Multi-database status (MySQL, PostgreSQL, Redis, Memcached)
- Connection monitoring
- Resource utilization
- Security configuration

## Customization Options

### Variables You Can Modify
```hcl
variable "web_instance_count" {
  default = 2  # Number of web servers
}

variable "database_instance_count" {
  default = 1  # Number of database servers
}

variable "project_name" {
  default = "terraform-network"  # Resource name prefix
}
```

### Adding More Servers
To scale the application:
```bash
# Increase web servers
terraform apply -var="web_instance_count=3"

# Add database servers  
terraform apply -var="database_instance_count=2"
```

## Security Best Practices Demonstrated

### 1. Network Segmentation
- Web servers in public subnet with restricted database access
- Database servers in private subnet with no direct internet access
- Bastion host as controlled access point

### 2. Security Group Design
- Principle of least privilege
- Service-specific rules (MySQL only from web servers)
- Remote group references for dynamic access control

### 3. SSH Security
- Key-based authentication only
- Bastion host pattern for private server access
- SSH ProxyCommand for transparent access

### 4. Monitoring and Logging
- Service health monitoring
- Automated restart capabilities
- Connection logging and analysis

## Common Issues and Solutions

### Cannot SSH to Database Server
This is expected! Database servers are only accessible via bastion:
```bash
# Correct way to access database servers
ssh -i terraform-key -o ProxyCommand='ssh -i terraform-key -W %h:%p ubuntu@<bastion-ip>' ubuntu@<db-ip>
```

### Web Servers Not Responding
Check security group rules and floating IP association:
```bash
terraform output web_servers_info
curl -v http://<web-server-ip>
```

### Network Connectivity Issues
Use bastion host network tools:
```bash
# From bastion host
sudo /opt/bastion-tools/network-scan.sh
sudo /opt/bastion-tools/connectivity-test.sh
```

### Database Connection Failures
Verify security group rules and service status:
```bash
# Check if MySQL is accessible from web subnet
mysql -h <db-ip> -u webapp -p
```

## PowerShell Networking Comparison

This setup is similar to PowerShell network management:

```powershell
# Create virtual switch (similar to OpenStack network)
New-VMSwitch -Name "Internal" -SwitchType Internal

# Configure subnets (similar to OpenStack subnets)
New-NetIPAddress -InterfaceAlias "vEthernet (Internal)" -IPAddress "10.0.1.1" -PrefixLength 24

# Firewall rules (similar to security groups)
New-NetFirewallRule -DisplayName "Allow Web" -Direction Inbound -Protocol TCP -LocalPort 80
New-NetFirewallRule -DisplayName "Allow MySQL" -Direction Inbound -Protocol TCP -LocalPort 3306 -RemoteAddress "10.0.1.0/24"

# NAT configuration (similar to OpenStack router)
New-NetNat -Name "InternalNAT" -InternalIPInterfaceAddressPrefix "10.0.1.0/24"
```

## Next Steps

After completing this exercise:
1. ✅ You understand advanced OpenStack networking
2. ✅ You can create secure multi-tier architectures
3. ✅ You know how to implement network segmentation
4. ✅ You can configure complex security group rules
5. ✅ You understand bastion host patterns

Move on to **Exercise 4: Storage and Volumes** to learn about persistent storage!

## Cleanup

To remove all resources:
```bash
terraform destroy
```

This will remove:
- All virtual machines and floating IPs
- Security groups and rules
- Network, subnets, and router
- SSH key pairs

The cleanup process ensures no orphaned resources remain in your OpenStack project.