# Exercise 3: Terraform Outputs

## Learning Objectives
- Understand how to define and use outputs in Terraform
- Learn different types of outputs (string, number, boolean, list, map, object)
- Practice using outputs for resource attributes and computed values
- Learn about sensitive outputs
- Understand how outputs can be used by other Terraform configurations

## What Are Outputs?
Outputs in Terraform are like return values from a function. They allow you to:
- Display important information after `terraform apply`
- Share data between Terraform configurations
- Expose resource attributes for external use
- Provide summary information about your infrastructure

## PowerShell Analogy
```powershell
# PowerShell function with return values
function New-Infrastructure {
    param($ProjectName, $Environment)
    
    # Create resources...
    $result = @{
        ProjectId = "$ProjectName-$Environment"
        FilesCreated = @("config.json", "app.yaml")
        TeamSize = 3
    }
    
    return $result  # This is like Terraform outputs
}

$deployment = New-Infrastructure -ProjectName "myapp" -Environment "dev"
Write-Host "Project ID: $($deployment.ProjectId)"
```

## Key Concepts Demonstrated

### 1. Output Types
- **String**: `output "project_name"`
- **Number**: `output "team_size"`
- **Boolean**: `output "monitoring_enabled"`
- **List**: `output "team_members"`
- **Object**: `output "team_details"`

### 2. Output Sources
- **Variables**: Direct variable values
- **Local Values**: Computed local values
- **Resource Attributes**: Properties of created resources
- **Conditional Logic**: Outputs that change based on conditions

### 3. Special Features
- **Sensitive Outputs**: Hidden from display (`sensitive = true`)
- **Conditional Outputs**: Only show when conditions are met
- **Formatted Outputs**: Multi-line strings with formatting
- **Complex Objects**: Nested data structures

## Commands to Run

```bash
# Initialize the exercise
terraform init

# See what will be created
terraform plan

# Apply the configuration
terraform apply

# View all outputs
terraform output

# View a specific output
terraform output project_name

# View a sensitive output (requires explicit request)
terraform output team_emails

# View output in JSON format
terraform output -json

# Clean up
terraform destroy
```

## Expected Outputs

After running `terraform apply`, you'll see outputs like:

```
Outputs:

deployment_summary = <<EOT
=====================================
TERRAFORM DEPLOYMENT SUMMARY
=====================================
Project: outputs-demo
Environment: DEVELOPMENT
Team Size: 3
Project ID: outputs-demo-development

Files Created:
- ./output/outputs-demo-development-info.json
- ./output/team-directory.yaml
- ./output/monitoring.conf

Deployed at: 2025-01-01T12:00:00Z
=====================================
EOT

environment_summary = {
  "metadata" = {
    "created_at" = "2025-01-01T12:00:00Z"
    "tags" = {
      "CreatedAt" = "2025-01-01T12:00:00Z"
      "Environment" = "development"
      "ManagedBy" = "Terraform"
      "Project" = "outputs-demo"
    }
  }
  "project" = {
    "environment" = "development"
    "id" = "outputs-demo-development"
    "name" = "outputs-demo"
  }
  "resources" = {
    "files_created" = 3
    "monitoring_enabled" = true
  }
  "team" = {
    "count" = 3
    "lead" = "alice"
    "members" = tolist([
      "alice",
      "bob", 
      "charlie",
    ])
  }
}

monitoring_enabled = true
project_identifier = "outputs-demo-development"
project_name = "outputs-demo"
team_size = 3
```

## Exercises to Try

1. **Modify Variables**: Change the project name and environment, then run `terraform plan` to see how outputs change

2. **Disable Monitoring**: Set `enable_monitoring = false` and see how conditional outputs change

3. **Add Team Members**: Add more names to the `team_members` list and observe the team-related outputs

4. **View Sensitive Output**: Try `terraform output team_emails` to see how sensitive outputs work

5. **JSON Output**: Use `terraform output -json > outputs.json` to save all outputs to a file

## Real-World Use Cases

Outputs are commonly used for:
- **API Endpoints**: Expose URLs of created load balancers or APIs
- **Database Connection Strings**: Provide connection information
- **Security Group IDs**: Share security group IDs between configurations
- **Resource ARNs**: Expose AWS resource ARNs for other services
- **IP Addresses**: Show public IP addresses of created instances

## Next Steps
- Try using these outputs as inputs to another Terraform configuration
- Experiment with more complex output expressions
- Learn about remote state and how outputs can be accessed across configurations