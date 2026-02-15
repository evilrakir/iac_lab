# OpenStack Provider Lab - Private Cloud Infrastructure

## 🎯 Learning Objectives

- Understand OpenStack as a private cloud platform
- Learn to manage OpenStack resources with Terraform
- Compare OpenStack concepts with Windows/Hyper-V
- Practice with compute, network, and storage resources
- Understand multi-tenant cloud architecture

## 🌟 Why OpenStack Matters

OpenStack is the **#1 open source private cloud platform**, used by:
- **CERN**: Runs the Large Hadron Collider computing
- **Walmart**: Powers their e-commerce infrastructure  
- **China Mobile**: Manages millions of subscribers
- **Your Enterprise**: Could replace expensive VMware licenses!

### OpenStack vs Public Cloud

| Aspect | OpenStack (Private) | AWS/Azure (Public) |
|--------|---------------------|-------------------|
| **Cost** | Predictable (hardware) | Variable (usage) |
| **Control** | Complete | Limited |
| **Compliance** | Full control | Shared responsibility |
| **Data Location** | On-premise | Cloud regions |
| **Customization** | Unlimited | Service limits |

## 🏗️ OpenStack Architecture

```
┌──────────────────────────────────────────────┐
│                   Horizon                     │ ← Web Dashboard
├──────────────────────────────────────────────┤
│                  Keystone                     │ ← Identity/Auth
├─────────┬──────────┬──────────┬──────────────┤
│  Nova   │ Neutron  │  Cinder  │    Swift     │
│(Compute)│(Network) │(Block)   │  (Object)    │ ← Core Services
├─────────┴──────────┴──────────┴──────────────┤
│              OpenStack API                    │
├──────────────────────────────────────────────┤
│          Hypervisor (KVM/VMware/Hyper-V)     │
└──────────────────────────────────────────────┘
```

## 🔄 Windows/Hyper-V to OpenStack Mapping

| Windows/Hyper-V | OpenStack | Purpose |
|-----------------|-----------|---------|
| Hyper-V Manager | Horizon Dashboard | Management UI |
| Virtual Machine | Nova Instance | Compute resources |
| Virtual Switch | Neutron Network | Network connectivity |
| VHDX Files | Cinder Volumes | Block storage |
| File Shares | Swift Containers | Object storage |
| Failover Cluster | OpenStack HA | High availability |
| Active Directory | Keystone | Identity management |
| Windows Firewall | Security Groups | Network security |

## 📚 What This Lab Covers

### 1. **Compute (Nova)**
- Creating virtual machine instances
- Managing SSH keypairs
- Using cloud-init for configuration
- Instance metadata and user data

### 2. **Networking (Neutron)**
- Creating virtual networks and subnets
- Configuring routers and gateways
- Security groups and rules
- Floating IPs for external access

### 3. **Storage**
- **Cinder**: Block storage volumes
- **Swift**: Object storage containers
- Volume attachments and snapshots

### 4. **Load Balancing (Octavia)**
- Creating load balancers
- Health monitoring
- Traffic distribution

## 🚀 Quick Start

### Prerequisites

1. **Option A: Real OpenStack**
   - Access to OpenStack cloud
   - Valid credentials
   - Project/tenant access

2. **Option B: DevStack (Learning)**
   ```bash
   # Requires Ubuntu 20.04/22.04 VM with 8GB RAM
   git clone https://opendev.org/openstack/devstack
   cd devstack
   ./stack.sh  # Takes ~30 minutes
   ```

3. **Option C: Just Learn**
   - Run the lab as-is for documentation
   - Resources are commented to avoid errors

### Setup Authentication

#### Method 1: Environment Variables
```powershell
# PowerShell
$env:OS_AUTH_URL = "http://openstack.local:5000/v3"
$env:OS_USERNAME = "admin"
$env:OS_PASSWORD = "password"
$env:OS_PROJECT_NAME = "demo"
$env:OS_USER_DOMAIN_NAME = "Default"
$env:OS_PROJECT_DOMAIN_NAME = "Default"
$env:OS_REGION_NAME = "RegionOne"
```

#### Method 2: clouds.yaml
Create `~/.config/openstack/clouds.yaml`:
```yaml
clouds:
  mycloud:
    auth:
      auth_url: http://openstack.local:5000/v3
      username: admin
      password: password
      project_name: demo
      user_domain_name: Default
      project_domain_name: Default
    region_name: RegionOne
```

### Run the Lab

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Create resources (if connected to OpenStack)
terraform apply

# View outputs
terraform output

# Clean up
terraform destroy
```

## 📝 Exercises

### Exercise 1: Basic Instance
Uncomment and create a single instance:
```hcl
resource "openstack_compute_instance_v2" "web" {
  name      = "web-server"
  image_id  = data.openstack_images_image_v2.ubuntu.id
  flavor_id = data.openstack_compute_flavor_v2.small.id
}
```

### Exercise 2: Network Security
Add a security group rule for RDP (Windows):
```hcl
resource "openstack_networking_secgroup_rule_v2" "rdp" {
  direction        = "ingress"
  protocol         = "tcp"
  port_range_min   = 3389
  port_range_max   = 3389
  remote_ip_prefix = "10.0.0.0/8"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}
```

### Exercise 3: Load Balanced Web Servers
Create multiple instances behind a load balancer:
```hcl
# Modify instance_count variable
variable "instance_count" {
  default = 3
}

# Instances and LB are already defined!
```

### Exercise 4: Persistent Storage
Add a larger volume for database storage:
```hcl
resource "openstack_blockstorage_volume_v3" "database" {
  name = "database-storage"
  size = 100  # 100GB
  
  # Optional: specify volume type for performance
  # volume_type = "ssd"
}
```

### Exercise 5: Object Storage
Upload application assets to Swift:
```hcl
resource "openstack_objectstorage_object_v1" "app_assets" {
  container_name = openstack_objectstorage_container_v1.container.name
  name           = "assets/logo.png"
  source         = "./files/logo.png"
  content_type   = "image/png"
}
```

## 🔍 Useful OpenStack Commands

```bash
# Instances
openstack server list
openstack server show <instance-name>
openstack console log show <instance-name>

# Networking  
openstack network list
openstack subnet list
openstack router list
openstack floating ip list

# Storage
openstack volume list
openstack container list
openstack object list <container>

# Images and Flavors
openstack image list
openstack flavor list

# Security
openstack security group list
openstack security group rule list <group>

# Quotas and Limits
openstack quota show
```

## 🐛 Troubleshooting

### Authentication Failed
```bash
# Verify credentials
openstack token issue

# Check auth URL (needs /v3 for Keystone v3)
echo $OS_AUTH_URL  # Should end with /v3
```

### No Valid Host Found
- Check flavor requirements vs available resources
- Verify quotas: `openstack quota show`
- Check compute service: `openstack compute service list`

### Network Connectivity Issues
- Verify security group rules allow traffic
- Check router has external gateway
- Ensure floating IP is associated

### Volume Attachment Failed
- Instance must be ACTIVE state
- Check volume is available
- Verify same availability zone

## 🏆 Real-World Scenarios

### Scenario 1: Web Application Stack
```
Internet → Floating IP → Load Balancer
                              ↓
                    ┌─────────┼─────────┐
                    ↓         ↓         ↓
                 Web-1     Web-2     Web-3
                    ↓         ↓         ↓
                    └─────────┼─────────┘
                              ↓
                         Database
                              ↓
                      Volume (100GB)
```

### Scenario 2: Development Environment
- Developers get their own project/tenant
- Quotas limit resource usage
- Networks isolated between projects
- Shared images for consistency

### Scenario 3: Disaster Recovery
- Primary site: OpenStack Region 1
- DR site: OpenStack Region 2
- Swift replication for objects
- Cinder backup to Swift
- Heat templates for quick rebuild

## 📊 Cost Comparison

### VMware vs OpenStack (100 VMs)
| Component | VMware | OpenStack |
|-----------|--------|-----------|
| Licenses | $250,000/year | $0 |
| Support | $50,000/year | $30,000/year (optional) |
| Training | $20,000 | $10,000 |
| **Total** | **$320,000/year** | **$40,000/year** |
| **Savings** | - | **87.5%** |

## 🎓 Learning Path

1. **This Lab** ← You are here!
2. **Heat Orchestration**: CloudFormation for OpenStack
3. **Magnum**: Kubernetes on OpenStack
4. **Ironic**: Bare metal provisioning
5. **TripleO**: OpenStack on OpenStack

## 📚 Additional Resources

- [OpenStack Documentation](https://docs.openstack.org)
- [OpenStack Academy](https://www.openstack.org/marketplace/training/)
- [Terraform OpenStack Provider Docs](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs)
- [OpenStack Ansible](https://docs.openstack.org/openstack-ansible/latest/)
- [Kolla-Ansible](https://docs.openstack.org/kolla-ansible/latest/) - Deploy OpenStack using containers

## 💡 Pro Tips

1. **Start with DevStack** for learning, not production
2. **Use Heat templates** for complex stacks
3. **Enable Ceilometer** for monitoring and billing
4. **Consider Magnum** for container workloads
5. **Use Designate** for DNS automation
6. **Implement Barbican** for secrets management

## 🏁 Next Steps

1. **Complete the exercises** in this lab
2. **Deploy DevStack** if you haven't already
3. **Try the Heat lab** for orchestration
4. **Explore Magnum** for Kubernetes
5. **Build a module** for your standard infrastructure

---

**Remember**: OpenStack is complex but powerful. Take it step by step, and you'll be managing private clouds like a pro! 🚀