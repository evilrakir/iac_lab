# Exercise: Understanding Terraform State

## Learning Objectives
- Understand what Terraform state is and why it's important
- Learn how to inspect and manage state
- Understand the relationship between configuration and state
- Practice using state commands
- Learn about state security and best practices

## What Is Terraform State?

Terraform state is a JSON file that tracks:
- What resources exist
- Their current properties
- Dependencies between resources
- Metadata about resources

Think of it as Terraform's "memory" of your infrastructure.

## PowerShell Analogy

```powershell
# PowerShell session state
$Global:ServerList = @()

# Creating a resource (like Terraform creating infrastructure)
function New-Server {
    param($Name, $IP)
    
    $server = @{
        Name = $Name
        IP = $IP
        Created = Get-Date
    }
    
    # Tracking in "state" (session variable)
    $Global:ServerList += $server
    
    return $server
}

# Checking state
function Get-ServerState {
    return $Global:ServerList
}

# This is similar to how Terraform tracks resources in state
```

## State File Structure

The `terraform.tfstate` file contains:

```json
{
  "version": 4,
  "terraform_version": "1.0.0",
  "serial": 1,
  "lineage": "unique-id",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "local_file",
      "name": "example",
      "provider": "provider[\"registry.terraform.io/hashicorp/local\"]",
      "instances": [
        {
          "attributes": {
            "content": "file content",
            "filename": "./example.txt"
          }
        }
      ]
    }
  ]
}
```

## Commands to Run

### Initial Setup
```bash
# Initialize Terraform
terraform init

# Create infrastructure and state
terraform apply

# View the state file (be careful, it may contain secrets!)
cat terraform.tfstate
```

### State Inspection Commands
```bash
# List all resources in state
terraform state list

# Show a specific resource
terraform state show local_file.state_example
terraform state show 'local_file.config_files[0]'
terraform state show 'local_file.service_configs["web"]'

# Show all resources
terraform show

# Show state in JSON format
terraform show -json | jq '.'
```

### State Management Commands
```bash
# Pull state to stdout
terraform state pull

# Remove a resource from state (doesn't destroy the actual resource)
terraform state rm local_file.manual_creation

# Move a resource in state
terraform state mv local_file.old_name local_file.new_name

# Import existing infrastructure into state
# First, create the resource block in your .tf file, then:
terraform import local_file.existing /path/to/existing/file.txt
```

### Workspace Commands
```bash
# List workspaces
terraform workspace list

# Create a new workspace
terraform workspace new development

# Switch to a workspace
terraform workspace select development

# Show current workspace
terraform workspace show

# Delete a workspace (must not be current)
terraform workspace delete old-workspace
```

## Exercises to Try

### 1. Inspect State
After applying, explore the state:
```bash
terraform state list
terraform state show random_id.state_id
```

### 2. Modify and Observe State Changes
Change the `version` in the `keepers` block of `random_id.state_id` from "1.0" to "2.0", then:
```bash
terraform plan  # See what will change
terraform apply # Apply changes
# Check terraform.tfstate.backup to see the previous state
```

### 3. Remove from State
Remove a resource from state without destroying it:
```bash
terraform state rm local_file.drift_demo
terraform plan  # Terraform will want to recreate it
```

### 4. Create State Drift
1. Manually edit one of the created files
2. Run `terraform plan` to see the drift
3. Run `terraform refresh` to update state from reality

### 5. Work with Sensitive Data
```bash
terraform state show random_password.secret
# Notice the value is shown despite being sensitive
# This is why state files must be protected!
```

## State Best Practices

### 1. State Security
- **State contains secrets**: Even "sensitive" values are in plaintext
- **Protect state files**: Use proper file permissions
- **Use remote state**: With encryption at rest
- **Enable state locking**: Prevent concurrent modifications

### 2. State Management
- **Never edit manually**: Use Terraform commands
- **Regular backups**: Especially before state operations
- **Version control**: Don't commit state to Git (use .gitignore)
- **State isolation**: Separate states for different environments

### 3. Team Collaboration
```hcl
# Example remote state configuration
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
    
    # Enable locking
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

## Common State Issues and Solutions

### Lost State File
**Problem**: State file deleted or corrupted
**Solution**: 
- Restore from backup (terraform.tfstate.backup)
- Recreate using `terraform import`
- Last resort: Delete resources manually and start fresh

### State Drift
**Problem**: Resources changed outside Terraform
**Solution**:
- `terraform refresh` to update state
- `terraform plan` to see differences
- Update configuration to match reality

### State Lock Error
**Problem**: "Error acquiring the state lock"
**Solution**:
- Someone else is running Terraform
- Or a previous run was interrupted
- Force unlock: `terraform force-unlock LOCK_ID`

## Real-World Scenarios

### 1. Import Existing Infrastructure
```bash
# Define the resource in configuration
# Then import it
terraform import aws_instance.example i-1234567890abcdef0
```

### 2. Refactoring Resources
```bash
# Rename a resource
terraform state mv aws_instance.old aws_instance.new

# Move to a module
terraform state mv aws_instance.example module.compute.aws_instance.example
```

### 3. Disaster Recovery
```bash
# Backup state before risky operations
terraform state pull > backup.tfstate

# If something goes wrong, restore
terraform state push backup.tfstate
```

## State Storage Options

### Local State (Default)
- File: `terraform.tfstate`
- Good for: Learning, development
- Bad for: Teams, production

### Remote State
- **S3**: AWS S3 with DynamoDB for locking
- **Azure Storage**: Azure Blob Storage
- **GCS**: Google Cloud Storage
- **Terraform Cloud**: Managed state storage
- **Consul**: HashiCorp Consul

## Next Steps
- Learn about remote state backends
- Practice state operations with real cloud resources
- Implement state locking for team collaboration
- Explore Terraform Cloud for managed state