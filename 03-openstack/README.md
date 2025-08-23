# OpenStack Infrastructure with Terraform

This section contains comprehensive exercises for learning Infrastructure as Code with OpenStack and Terraform. These exercises progress from basic provider setup to advanced multi-tier architectures with load balancing and storage management.

## 🎯 Learning Path

### Exercise 1: Provider Setup
**📁 01-provider-setup**
- Configure OpenStack Terraform provider
- Set up authentication (environment variables, application credentials)
- Test cloud connectivity and resource discovery
- Understand OpenStack API endpoints and regions

### Exercise 2: Basic VM Deployment  
**📁 02-basic-vm**
- Deploy your first virtual machine
- Configure security groups and network access
- Set up SSH key authentication
- Implement automated VM configuration with user-data
- Assign floating IPs for external access

### Exercise 3: Advanced Networking
**📁 03-networking**
- Create custom network topologies with multiple subnets
- Implement network segmentation (web tier, database tier)
- Deploy bastion host for secure private access
- Configure advanced security group rules
- Set up multi-server architectures with proper isolation

### Exercise 4: Storage Management
**📁 04-storage**
- Create and attach block storage volumes
- Configure different file systems (XFS, ext4)
- Implement automated backup strategies
- Set up volume snapshots for disaster recovery
- Configure shared storage with NFS
- Monitor storage performance and health

### Exercise 5: Load Balancing
**📁 05-load-balancer**
- Deploy OpenStack load balancers
- Configure health checks and pool management
- Implement high availability web applications
- Set up automatic failover and redundancy
- Monitor load balancer performance and traffic distribution

## 🏗️ Architecture Progression

### Exercise 1: Basic Connectivity
```
Developer → OpenStack API → Resource Discovery
```

### Exercise 2: Single VM
```
Internet → Floating IP → VM → Security Group → Private Network
```

### Exercise 3: Multi-Tier Architecture
```
Internet → Router → Web Subnet (Bastion + Web Servers)
                 → DB Subnet (Database Servers)
```

### Exercise 4: Storage-Enhanced Architecture
```
Web Servers + Data Volumes + Backup Volumes
     ↓              ↓            ↓
NFS Shared Storage ← → Local Storage → Automated Backups
```

### Exercise 5: Load-Balanced Architecture
```
Internet → Load Balancer → Multiple Web Servers
              ↓                    ↓
         Health Checks    → Storage Backend
              ↓                    ↓
         Pool Management  → Database Tier
```

## 🛠️ Prerequisites

### Required Tools
- **Terraform** 1.0+ (installed at C:\Tools\Terraform\terraform.exe)
- **OpenStack CLI** (optional, for manual operations)
- **SSH client** (for instance access)
- **PowerShell 5.1+** (for interactive guides)

### OpenStack Access
- OpenStack cloud environment access
- User credentials with appropriate permissions:
  - Compute: VM creation, flavor/image access
  - Network: Network/subnet creation, security groups, floating IPs
  - Storage: Volume creation and attachment
  - Load Balancer: LBaaS configuration (if available)

### Authentication Setup
Set these environment variables before starting:

```powershell
$env:OS_AUTH_URL = "https://your-openstack.example.com:5000/v3"
$env:OS_USERNAME = "your-username"
$env:OS_PASSWORD = "your-password"
$env:OS_PROJECT_NAME = "your-project"
$env:OS_USER_DOMAIN_NAME = "Default"
$env:OS_PROJECT_DOMAIN_NAME = "Default"
$env:OS_REGION_NAME = "RegionOne"
```

## 🚀 Getting Started

### Quick Start
1. **Set up authentication** (see above)
2. **Run the interactive lab**:
   ```powershell
   .\Start-TerraformLab.ps1
   ```
3. **Select OpenStack exercises** from the menu
4. **Follow the guided workflow** for each exercise

### Manual Exercise Execution
```powershell
# Navigate to specific exercise
cd 03-openstack\01-provider-setup

# Run interactive guide
.\interactive-guide.ps1

# Or run manually
terraform init
terraform plan
terraform apply
```

## 📚 Exercise Details

### Common Patterns Across All Exercises

Each exercise includes:
- **main.tf** - Primary Terraform configuration
- **README.md** - Detailed documentation and learning objectives
- **interactive-guide.ps1** - PowerShell guided walkthrough
- **User-data scripts** - Automated instance configuration
- **Variable files** - Customization examples

### Learning Objectives

By completing all OpenStack exercises, you will:

#### 🔧 Technical Skills
- Master OpenStack Terraform provider configuration
- Deploy and manage virtual machines at scale
- Design secure network architectures
- Implement persistent storage solutions
- Configure load balancing and high availability

#### 🏗️ Architecture Skills
- Design multi-tier cloud applications
- Implement security best practices
- Plan for disaster recovery and backups
- Optimize for performance and cost
- Understand cloud networking concepts

#### 🔄 DevOps Skills
- Infrastructure as Code best practices
- Automated deployment pipelines
- Monitoring and alerting strategies
- Change management with Terraform
- Documentation and knowledge sharing

## 🔍 Advanced Topics

### Security Best Practices
- Network segmentation with security groups
- SSH key management and rotation
- Bastion host patterns for secure access
- Principle of least privilege for service accounts
- Encrypted storage and secure communications

### High Availability Patterns
- Multi-availability zone deployments
- Load balancer health checks and failover
- Database replication and backup strategies
- Automated scaling and recovery
- Disaster recovery planning

### Performance Optimization
- Storage performance tuning (XFS vs ext4)
- Network optimization for multi-tier apps
- Load balancer algorithm selection
- Resource sizing and capacity planning
- Monitoring and alerting for performance

## 🧪 Testing and Validation

### Automated Testing
Each exercise includes validation scripts:
- **Connectivity tests** - Verify network access
- **Service health checks** - Confirm application functionality  
- **Performance benchmarks** - Measure system performance
- **Security scans** - Validate configuration compliance

### Manual Testing
Interactive testing procedures:
- SSH access verification
- Web application functionality
- Database connectivity
- Load balancer traffic distribution
- Storage performance and backups

## 🔧 Troubleshooting

### Common Issues

#### Authentication Problems
```powershell
# Verify credentials
openstack token issue

# Check environment variables
Get-ChildItem env: | Where-Object Name -like "OS_*"
```

#### Network Connectivity
```bash
# Test OpenStack API
curl -k $OS_AUTH_URL

# Verify security group rules
openstack security group rule list <group-id>
```

#### Resource Quotas
```bash
# Check quotas
openstack quota show
openstack volume quota show
```

### Getting Help
- 📖 **Exercise README files** - Detailed troubleshooting sections
- 🔧 **Interactive guides** - Built-in error handling and suggestions
- 📊 **Web dashboards** - Real-time monitoring and diagnostics
- 🤝 **Community resources** - OpenStack and Terraform documentation

## 🧹 Cleanup

### Exercise-Level Cleanup
```bash
# From each exercise directory
terraform destroy
```

### Complete Cleanup
```powershell
# Clean all OpenStack exercises
foreach ($exercise in @("01-provider-setup", "02-basic-vm", "03-networking", "04-storage", "05-load-balancer")) {
    cd "03-openstack\$exercise"
    terraform destroy -auto-approve
    cd ..\..
}
```

### Verification
```bash
# Verify no resources remain
openstack server list
openstack volume list
openstack network list --internal
openstack loadbalancer list
```

## 📈 Next Steps

After completing the OpenStack exercises:

1. **Explore advanced Terraform features**:
   - Modules and reusable components
   - Remote state management
   - Terraform Cloud/Enterprise
   - Policy as Code with Sentinel

2. **Integrate with CI/CD pipelines**:
   - GitLab CI/CD with Terraform
   - GitHub Actions for infrastructure
   - Azure DevOps Terraform integration
   - Jenkins pipeline automation

3. **Learn additional cloud platforms**:
   - AWS with Terraform
   - Azure Resource Manager
   - Google Cloud Platform
   - Multi-cloud strategies

4. **Advanced infrastructure patterns**:
   - Microservices architectures
   - Container orchestration (Kubernetes)
   - Serverless computing
   - Edge computing deployments

## 🎖️ Certification and Learning

### Recommended Certifications
- **HashiCorp Certified: Terraform Associate**
- **OpenStack Certified Administrator (COA)**
- **Cloud architecture certifications** (AWS, Azure, GCP)

### Additional Learning Resources
- **HashiCorp Learn** - Official Terraform tutorials
- **OpenStack Documentation** - Comprehensive platform guides
- **Cloud Architecture Patterns** - Design best practices
- **Infrastructure as Code** - DevOps methodologies

---

**Ready to start your OpenStack journey?** Begin with Exercise 1: Provider Setup to configure your first OpenStack Terraform environment! 🚀