# Exercise 1: OpenStack Provider Setup

## Learning Objectives

In this exercise, you will:
- Configure the OpenStack Terraform provider
- Learn different authentication methods
- Discover available OpenStack resources
- Understand data sources for resource discovery

## Prerequisites

- Access to an OpenStack cloud environment
- OpenStack credentials (username/password or application credentials)
- Basic understanding of Terraform providers

## OpenStack Authentication Methods

### Method 1: Environment Variables (Recommended)

Set these environment variables in PowerShell:
```powershell
$env:OS_AUTH_URL = "https://your-openstack.example.com:5000/v3"
$env:OS_USERNAME = "your-username"
$env:OS_PASSWORD = "your-password"
$env:OS_PROJECT_NAME = "your-project"
$env:OS_USER_DOMAIN_NAME = "Default"
$env:OS_PROJECT_DOMAIN_NAME = "Default"
$env:OS_REGION_NAME = "RegionOne"
```

### Method 2: Application Credentials (For Automation)

Create application credentials in OpenStack Horizon:
1. Go to Identity → Application Credentials
2. Create New Application Credential
3. Use the ID and secret in your configuration

### Method 3: Direct Configuration (Development Only)

Uncomment and modify the provider block in `main.tf`:
```hcl
provider "openstack" {
  auth_url    = "https://your-openstack.example.com:5000/v3"
  user_name   = "your-username"
  password    = "your-password"
  tenant_name = "your-project"
  domain_name = "Default"
  region      = "RegionOne"
}
```

## Exercise Steps

### 1. Configure Authentication

Choose and configure one of the authentication methods above.

### 2. Initialize Terraform

```bash
terraform init
```

This will download the OpenStack provider.

### 3. Plan the Configuration

```bash
terraform plan
```

This will attempt to connect to OpenStack and discover resources.

### 4. Apply the Configuration

```bash
terraform apply
```

This will query OpenStack and output available resources.

## Understanding the Code

### Provider Configuration
```hcl
provider "openstack" {
  # Authentication configuration
}
```

The provider block configures how Terraform connects to OpenStack.

### Data Sources
```hcl
data "openstack_images_image_v2" "ubuntu" {
  name        = "Ubuntu 22.04"
  most_recent = true
}
```

Data sources allow you to query existing OpenStack resources.

### Authentication Scope
```hcl
data "openstack_identity_auth_scope_v3" "scope" {
  name = "my_scope"
}
```

Shows your current authentication context and permissions.

## Expected Output

After applying, you should see:
- Your authentication scope (project, user, roles)
- Available Ubuntu image details
- Small flavor specifications
- Network information

## Common Issues

### Authentication Failures
- Verify your credentials are correct
- Check the auth_url endpoint
- Ensure your user has proper roles in the project

### Resource Not Found
- Ubuntu image name might be different in your cloud
- Flavor names vary between deployments
- Network names are environment-specific

### Connection Issues
- Verify network connectivity to OpenStack API
- Check if API endpoints are accessible
- Verify SSL certificates if using HTTPS

## PowerShell Comparison

This is similar to PowerShell's authentication methods:

```powershell
# PowerShell credential management
$credential = Get-Credential
Connect-Service -Credential $credential

# Environment variables
$env:SERVICE_TOKEN = "your-token"
Connect-Service -UseEnvironment
```

## Next Steps

After completing this exercise:
1. You'll have a working OpenStack provider configuration
2. You'll understand resource discovery methods
3. You'll be ready to create actual OpenStack resources

Move on to Exercise 2: Basic VM Deployment to start creating infrastructure!

## Security Notes

- Never commit credentials to version control
- Use environment variables or application credentials for production
- Rotate credentials regularly
- Use least-privilege access principles