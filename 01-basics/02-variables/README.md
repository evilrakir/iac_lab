# Exercise 2: Variables and Input Values

## 🎯 Learning Objectives

- Master all Terraform variable types (string, number, bool, list, map, set, object)
- Understand variable validation and constraints
- Learn the difference between variables and locals
- Practice variable precedence and override methods
- Implement conditional logic with variables
- Compare Terraform variables to PowerShell parameters

## 📋 Prerequisites

- Completed Exercise 1 (Hello World)
- Basic understanding of Terraform syntax
- Familiarity with PowerShell parameters and validation

## 🚀 Quick Start

### Using the Lab Launcher

```powershell
# From the main lab directory
cd C:\lappyshare\dev\lab
.\Start-TerraformLab.ps1

# Select "01-basics/02-variables" from the menu
# Choose GUIDED MODE for step-by-step learning
```

### Manual Commands

```powershell
cd 01-basics/02-variables
terraform init
terraform plan
terraform apply
```

## 📚 What You'll Learn

### 1. Variable Types

This exercise demonstrates all Terraform variable types:

| Type | Description | PowerShell Equivalent |
|------|-------------|----------------------|
| `string` | Text values | `[string]$var` |
| `number` | Numeric values | `[int]$var` or `[double]$var` |
| `bool` | True/false | `[bool]$var` |
| `list(type)` | Ordered collection | `[type[]]$var` |
| `set(type)` | Unique unordered collection | Array with `Select-Object -Unique` |
| `map(type)` | Key-value pairs | `[hashtable]$var` |
| `object({...})` | Structured data | `[PSCustomObject]@{...}` |

### 2. Variable Validation

Learn how to add validation rules:

```hcl
variable "port_number" {
  type    = number
  default = 8080
  
  validation {
    condition     = var.port_number >= 1024 && var.port_number <= 65535
    error_message = "Port must be between 1024 and 65535."
  }
}
```

PowerShell equivalent:
```powershell
[ValidateRange(1024, 65535)]
[int]$PortNumber = 8080
```

### 3. Local Values

Locals are computed values derived from variables:

```hcl
locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  instance_type   = var.environment == "production" ? "t2.large" : "t2.micro"
}
```

### 4. Variable Precedence

Variables can be set in multiple ways (highest to lowest priority):

1. Command line: `-var="key=value"`
2. Variable files: `-var-file="custom.tfvars"`
3. Environment variables: `TF_VAR_variable_name`
4. `terraform.tfvars` file
5. `*.auto.tfvars` files
6. Default values in variable definitions

## 🔍 Exercise Structure

### Files Created

- `variable-values.txt` - Shows all variable values
- `instances/instance-N.yaml` - Instance configurations using count
- `servers/SERVER.conf` - Server configs using for_each
- `monitoring.conf` - Conditional resource (if enabled)
- `terraform-vs-powershell-variables.ps1` - Comparison script

### Key Concepts Demonstrated

1. **All Variable Types** - Every type with practical examples
2. **Validation Rules** - Range, pattern, and set validation
3. **Sensitive Variables** - Handling secrets safely
4. **Optional Variables** - Using null values
5. **Complex Objects** - Nested data structures
6. **Local Values** - Computed and derived values
7. **Conditional Resources** - Using count with conditions
8. **Loops** - Both count and for_each patterns

## 🎮 Hands-On Tasks

### Task 1: Override Variables

Try different ways to override variables:

```powershell
# Method 1: Command line
terraform apply -var="environment=production"

# Method 2: Variable file
echo 'environment = "staging"' > custom.tfvars
terraform apply -var-file="custom.tfvars"

# Method 3: Environment variable
$env:TF_VAR_environment = "production"
terraform apply
```

### Task 2: Validation Testing

Try invalid values to see validation in action:

```powershell
terraform apply -var="port_number=80"     # Too low
terraform apply -var="environment=test"   # Invalid option
terraform apply -var="instance_count=15"  # Too high
```

### Task 3: Modify Complex Variables

Create a `terraform.tfvars` file:

```hcl
server_configs = [
  {
    name = "api-1"
    size = "t2.large"
    role = "api-gateway"
  },
  {
    name = "cache-1"
    size = "t2.small"
    role = "redis-cache"
  }
]

tags = {
  Team        = "DevOps"
  Environment = "Production"
  CostCenter  = "IT-001"
}
```

## 💡 Tips and Best Practices

1. **Use Descriptive Names** - Variable names should be self-documenting
2. **Add Descriptions** - Always include the `description` argument
3. **Set Appropriate Defaults** - But don't set defaults for sensitive values
4. **Use Validation** - Catch errors early with validation rules
5. **Leverage Locals** - For computed values and to avoid repetition
6. **Mark Sensitive Data** - Use `sensitive = true` for secrets
7. **Document Variable Files** - Comment your `.tfvars` files

## 🔗 Variable Precedence Example

```powershell
# Create terraform.tfvars (auto-loaded)
@'
project_name = "my-app"
environment  = "staging"
'@ | Set-Content terraform.tfvars

# Create production.tfvars (must specify)
@'
environment     = "production"
instance_count  = 5
'@ | Set-Content production.tfvars

# Test precedence
terraform plan                              # Uses terraform.tfvars
terraform plan -var-file="production.tfvars" # Overrides with production
terraform plan -var="environment=dev"       # Command line wins
```

## 📊 Comparison with PowerShell

| Terraform | PowerShell | Key Difference |
|-----------|------------|----------------|
| `variable` blocks | `param()` block | Terraform is declarative |
| `validation` block | `[ValidateX()]` attributes | Similar concept |
| `locals` block | Regular variables | Locals are computed once |
| `sensitive = true` | `[SecureString]` | Both hide sensitive data |
| `type = object({})` | `[PSCustomObject]` | Terraform enforces structure |

## 🚦 Validation Checklist

After completing this exercise, you should be able to:

- [ ] Define variables of all types
- [ ] Add validation rules to variables
- [ ] Use locals for computed values
- [ ] Override variables using different methods
- [ ] Create conditional resources
- [ ] Use both count and for_each
- [ ] Handle sensitive data properly
- [ ] Understand variable precedence

## 🎯 Next Steps

1. Experiment with different variable combinations
2. Try creating your own validation rules
3. Practice overriding variables
4. Move to Exercise 3: Outputs and Data Sharing

---

**Remember**: Variables make your Terraform configurations flexible and reusable. Master them and you'll write better Infrastructure as Code!