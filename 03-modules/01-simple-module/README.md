# Exercise: Creating and Using Terraform Modules

## Learning Objectives
- Understand what Terraform modules are and why they're useful
- Learn how to create a reusable module
- Practice using modules with different configurations
- Understand module inputs (variables) and outputs
- Learn module best practices and patterns

## What Are Terraform Modules?
Modules are containers for multiple resources that are used together. They're like functions in programming - reusable pieces of infrastructure code that accept inputs and return outputs.

## PowerShell Analogy
```powershell
# PowerShell function (like a Terraform module)
function New-AppConfiguration {
    param(
        [Parameter(Mandatory)]
        [string]$AppName,
        
        [Parameter(Mandatory)]
        [string]$Environment,
        
        [string]$Version = "1.0.0",
        [int]$Port = 8080
    )
    
    # Create configuration (like module resources)
    $config = @{
        Name = $AppName
        Environment = $Environment
        Version = $Version
        Port = $Port
    }
    
    # Return values (like module outputs)
    return $config
}

# Using the function (like calling a module)
$webApp = New-AppConfiguration -AppName "web" -Environment "dev"
$apiApp = New-AppConfiguration -AppName "api" -Environment "prod" -Port 3000
```

## Module Structure

### Our Module (`my-first-module/`)
- **main.tf** - Resources the module creates
- **variables.tf** - Input parameters the module accepts
- **outputs.tf** - Values the module returns

### Root Configuration
- **main.tf** - Calls the module with different configurations

## Key Concepts Demonstrated

### 1. Module Inputs (Variables)
- **Required inputs**: Must be provided (no defaults)
- **Optional inputs**: Have default values
- **Variable validation**: Ensures inputs are valid

### 2. Module Outputs
- Return values from the module
- Can be used by other resources
- Can be sensitive (hidden from display)

### 3. Module Instances
- **Single instance**: Basic module call
- **Multiple instances**: Same module, different configs
- **Conditional**: Using `count` to conditionally create
- **Dynamic**: Using `for_each` for multiple instances

### 4. Module Composition
- Modules can use other modules
- Outputs from one module can be inputs to another
- Creates layers of abstraction

## Commands to Run

```bash
# Initialize (downloads providers)
terraform init

# Validate the configuration
terraform validate

# See what will be created
terraform plan

# Create the infrastructure
terraform apply

# View specific module outputs
terraform output -module=web_app

# View all outputs
terraform output

# Clean up
terraform destroy
```

## Expected Results

After running `terraform apply`, you'll see:
- Multiple configuration files created by different module instances
- Each module instance has its own set of files
- A deployment manifest aggregating all module outputs
- Different configurations for dev, staging, and production

## Exercises to Try

### 1. Modify Module Defaults
Edit `my-first-module/variables.tf` to change default values, then run `terraform plan` to see the impact.

### 2. Add a New Module Instance
In `main.tf`, add a new module block:
```hcl
module "test_app" {
  source = "./my-first-module"
  
  app_name    = "test-service"
  environment = "dev"
  port        = 9000
}
```

### 3. Create a New Output
Add a new output to `my-first-module/outputs.tf`:
```hcl
output "app_url" {
  description = "Application URL"
  value       = "http://localhost:${var.port}/${var.app_name}"
}
```

### 4. Add Input Validation
Add validation to a variable in `my-first-module/variables.tf`:
```hcl
validation {
  condition     = length(var.app_name) >= 3
  error_message = "App name must be at least 3 characters."
}
```

### 5. Use Module Outputs
Reference module outputs in a new resource:
```hcl
resource "local_file" "urls" {
  filename = "app-urls.txt"
  content  = <<-EOT
    Web App: http://localhost:${module.web_app.port}
    API Service: http://localhost:${module.api_service.port}
  EOT
}
```

## Real-World Use Cases

Modules are commonly used for:
- **Network modules**: VPC, subnets, security groups
- **Compute modules**: EC2 instances, auto-scaling groups
- **Database modules**: RDS instances with standardized settings
- **Application modules**: Complete application stacks
- **Security modules**: IAM roles, policies, encryption

## Module Sources

Modules can come from various sources:
```hcl
# Local path
module "local" {
  source = "./modules/my-module"
}

# Terraform Registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"
}

# Git repository
module "git" {
  source = "git::https://github.com/example/module.git"
}

# Git with specific ref
module "git_tag" {
  source = "git::https://github.com/example/module.git?ref=v1.0.0"
}
```

## Best Practices

1. **Keep modules focused**: One module should do one thing well
2. **Use semantic versioning**: Tag your modules with versions
3. **Document thoroughly**: Include README with examples
4. **Validate inputs**: Use validation blocks
5. **Provide sensible defaults**: Make modules easy to use
6. **Output useful values**: Think about what consumers need
7. **Test your modules**: Create test configurations
8. **Version your modules**: Use version constraints

## Next Steps
- Create more complex modules with multiple resources
- Learn about module versioning and the Terraform Registry
- Explore published modules for AWS, Azure, or GCP
- Build a module library for your organization