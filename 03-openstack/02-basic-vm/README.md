# Exercise 2: Basic VM Deployment

## Learning Objectives

In this exercise, you will:
- Deploy your first virtual machine in OpenStack using Terraform
- Create and configure security groups for network access
- Set up SSH key pairs for secure access
- Use user-data scripts for automated VM configuration
- Understand floating IPs for external connectivity
- Learn about VM metadata and tagging

## Prerequisites

- Completed Exercise 1 (OpenStack Provider Setup)
- SSH key pair generated (or will be created during exercise)
- Access to OpenStack cloud with VM creation permissions

## What You'll Create

This exercise creates:
- 🖥️ **Virtual Machine** - Ubuntu 22.04 instance
- 🔒 **Security Group** - Network access rules (SSH, HTTP, HTTPS, ICMP)
- 🔑 **Key Pair** - SSH authentication
- 🌐 **Optional Floating IP** - External network access
- ⚙️ **User Data Script** - Automated software installation

## Exercise Files

- `main.tf` - Main Terraform configuration
- `user-data.sh` - VM initialization script
- `terraform.tfvars.example` - Example variables
- `interactive-guide.ps1` - PowerShell guide
- `README.md` - This documentation

## Quick Start

### 1. Generate SSH Key Pair

If you don't have an SSH key pair, create one:

```bash
ssh-keygen -t rsa -b 4096 -f terraform-key -N ""
```

This creates:
- `terraform-key` - Private key (keep secure!)
- `terraform-key.pub` - Public key (uploaded to OpenStack)

### 2. Configure Variables (Optional)

Copy and customize the variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to match your OpenStack environment:

```hcl
instance_name = "my-vm"
flavor_name   = "m1.small"
image_name    = "Ubuntu 22.04"
network_name  = "internal"
create_floating_ip = true  # Set to true for external access
```

### 3. Deploy the Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 4. Access Your VM

After deployment, Terraform will output connection information:

```bash
# View connection details
terraform output

# Connect via SSH
ssh -i terraform-key ubuntu@<ip-address>

# Test web server
curl http://<ip-address>
```

## Understanding the Configuration

### Security Group Rules

```hcl
resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.vm_secgroup.id
}
```

This creates firewall rules allowing:
- **SSH (22)** - Secure shell access
- **HTTP (80)** - Web server traffic
- **HTTPS (443)** - Secure web traffic
- **ICMP** - Ping connectivity

### VM Configuration

```hcl
resource "openstack_compute_instance_v2" "vm" {
  name            = var.instance_name
  image_id        = data.openstack_images_image_v2.vm_image.id
  flavor_id       = data.openstack_compute_flavor_v2.vm_flavor.id
  key_pair        = openstack_compute_keypair_v2.vm_keypair.name
  security_groups = [openstack_networking_secgroup_v2.vm_secgroup.name]
  
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    hostname = var.instance_name
  }))
}
```

Key components:
- **Image/Flavor** - VM size and operating system
- **Key Pair** - SSH authentication method
- **Security Groups** - Network access control
- **User Data** - Automated configuration script

### User Data Script

The `user-data.sh` script automatically:
- Updates system packages
- Installs nginx web server
- Creates a custom welcome page
- Sets up system monitoring endpoints
- Configures the system hostname

## Floating IPs

Floating IPs provide external internet access:

```hcl
resource "openstack_networking_floatingip_v2" "vm_fip" {
  count = var.create_floating_ip ? 1 : 0
  pool  = data.openstack_networking_network_v2.external.name
}
```

Set `create_floating_ip = true` to enable external access.

## Testing Your Deployment

### 1. Verify VM Status

```bash
# Check Terraform outputs
terraform output instance_info

# View all outputs
terraform output
```

### 2. Test Network Connectivity

```bash
# Ping test
ping <vm-ip-address>

# Web server test
curl http://<vm-ip-address>

# SSH connection test
ssh -i terraform-key ubuntu@<vm-ip-address>
```

### 3. Explore the Web Interface

Open `http://<vm-ip-address>` in your browser to see:
- Welcome page with instance information
- System status information
- Network configuration details

### 4. SSH and Explore

```bash
# Connect to your VM
ssh -i terraform-key ubuntu@<vm-ip-address>

# Check system status
sudo systemctl status nginx
curl localhost/system-info
curl localhost/network-info

# Explore the system
htop
df -h
free -h
```

## Common Issues and Solutions

### SSH Key Problems
```bash
# Ensure correct permissions
chmod 600 terraform-key
chmod 644 terraform-key.pub

# Verify key format
ssh-keygen -l -f terraform-key.pub
```

### Flavor Not Found
Update your `terraform.tfvars`:
```hcl
flavor_name = "standard.small"  # or whatever your cloud uses
```

### Image Not Found
Find available images:
```bash
openstack image list
```

Update your configuration:
```hcl
image_name = "ubuntu-22.04"  # exact name from your cloud
```

### Network Issues
Check available networks:
```bash
openstack network list
```

Update network name:
```hcl
network_name = "private"  # or your network name
```

### Security Group Access
If you can't connect:
- Verify security group rules are created
- Check if your IP is allowed (0.0.0.0/0 allows all)
- Ensure floating IP is associated (if using external access)

## PowerShell Comparison

This Terraform configuration is similar to PowerShell VM management:

```powershell
# PowerShell equivalent concepts
New-VM -Name "MyVM" -ImagePath "Ubuntu22.04.vhdx"
Set-VMProcessor -VMName "MyVM" -Count 2
Set-VMMemory -VMName "MyVM" -DynamicMemoryEnabled $false -StartupBytes 4GB

# Network configuration
New-VMSwitch -Name "VMNetwork" -SwitchType External
Add-VMNetworkAdapter -VMName "MyVM" -SwitchName "VMNetwork"

# Security (Windows Firewall rules)
New-NetFirewallRule -DisplayName "Allow SSH" -Direction Inbound -Protocol TCP -LocalPort 22
```

## Next Steps

After completing this exercise:
1. ✅ You have a running VM in OpenStack
2. ✅ You understand security groups and networking
3. ✅ You can use SSH keys for authentication
4. ✅ You've automated VM configuration with user-data

Move on to **Exercise 3: Networking and Security Groups** to learn advanced networking concepts!

## Cleanup

To remove all resources:

```bash
terraform destroy
```

This will:
- Terminate the virtual machine
- Remove the floating IP (if created)
- Delete the security group
- Remove the key pair
- Clean up all associated resources

## Security Best Practices

- ✅ Use SSH keys instead of passwords
- ✅ Restrict security group rules to necessary ports
- ✅ Regularly update and patch your VMs
- ✅ Use specific IP ranges instead of 0.0.0.0/0 when possible
- ✅ Tag resources for better organization
- ✅ Keep private keys secure and never commit them to version control