# Terraform Learning Lab - Best Practices

This document outlines the best practices for both using and developing the Terraform Learning Lab.

## For Students

### Getting Started
1. **Always start with the Hello World exercise** - Even if you know Terraform, it establishes the workflow
2. **Use Guided Mode first** - It explains each command and concept step-by-step
3. **Read the comments in .tf files** - They contain important learning notes
4. **Don't skip `terraform plan`** - Always preview changes before applying

### Command Workflow
```bash
terraform init    # Initialize providers (like npm install)
terraform plan    # Preview changes (like PowerShell -WhatIf)
terraform apply   # Create resources (requires 'yes' confirmation)
terraform show    # View current state
terraform destroy # Clean up resources (requires 'yes' confirmation)
```

### Lab System Commands
```powershell
# Start the lab
.\Start-TerraformLab.ps1

# View your progress
.\Start-TerraformLab.ps1 -ShowStats

# Reset all progress (start fresh)
.\Start-TerraformLab.ps1 -ResetProgress

# Skip prerequisites for testing
.\Start-TerraformLab.ps1 -Exercise "01-basics/02-variables" -SkipPrerequisites
```

### Common Issues and Solutions

#### "Required plugins are not installed"
- **Cause**: The `.terraform` directory was cleaned but providers weren't re-initialized
- **Solution**: Run `terraform init` before other commands
- **Prevention**: The lab now auto-initializes when needed

#### "Cannot find template file"
- **Cause**: Template files (*.tftpl) weren't copied or null values weren't handled
- **Solution**: Ensure template files handle null values with conditionals
- **Example**: `${var.custom_domain != null ? var.custom_domain : "Not configured"}`

#### "Output files not found"
- **Cause**: Looking in wrong directory or files were cleaned up
- **Solution**: Files are created in `./terraform-lab-output/` within each exercise directory
- **Reset**: Use menu option 8 "Reset this exercise" to clean and start fresh

## Standardization Process

### When Applying Best Practices to Existing Labs
When updating exercises to follow best practices:

1. **Path Standardization**:
   - Replace `${path.module}/output/` with `./terraform-lab-output/`
   - Replace any other custom output paths with standardized location
   - Ensure modules accept `output_path` variable but default to `./terraform-lab-output/`

2. **PowerShell Comparison Files**:
   - Add `terraform-vs-powershell-*.ps1` resource to each exercise
   - Show equivalent PowerShell commands/patterns
   - Highlight key differences between declarative and imperative approaches

3. **Template Files**:
   - Pre-create template files instead of generating at runtime
   - Handle null values with conditionals: `${var != null ? var : "Default"}`
   - Store templates in exercise directory, not in temp locations

4. **Testing Each Change**:
   ```bash
   terraform init
   terraform apply -auto-approve
   # Verify outputs in ./terraform-lab-output/
   terraform destroy -auto-approve
   rm -rf .terraform terraform.tfstate* terraform-lab-output
   ```

## For Lab Developers

### Exercise Structure
Each exercise must have:
```
exercise-name/
├── main.tf           # Primary resource definitions
├── variables.tf      # Input variable definitions  
├── outputs.tf        # Output definitions
├── terraform.tfvars  # Default variable values (optional)
├── *.tftpl          # Template files (if needed)
└── README.md        # Exercise documentation
```

### Variable Best Practices

1. **Always provide descriptions**:
```hcl
variable "environment" {
  description = "Deployment environment (development, staging, production)"
  type        = string
  default     = "development"
}
```

2. **Use appropriate types**:
```hcl
variable "instance_count" {
  type    = number
  default = 3
}

variable "tags" {
  type = map(string)
  default = {
    Project = "TerraformLab"
  }
}
```

3. **Add validation where appropriate**:
```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}
```

4. **Handle nullable variables in templates**:
```hcl
# In template file (.tftpl)
Custom Domain: ${custom_domain != null ? custom_domain : "Not configured"}
Backup Days: ${backup_retention != null ? "${backup_retention} days" : "Not configured"}
```

### Output Best Practices

1. **Always use descriptions**:
```hcl
output "instance_ids" {
  description = "IDs of created instances"
  value       = local_file.instance_configs[*].id
}
```

2. **Mark sensitive outputs**:
```hcl
output "api_key" {
  description = "API key for service access"
  value       = random_password.api_key.result
  sensitive   = true
}
```

3. **Provide helpful formatted outputs**:
```hcl
output "summary" {
  description = "Human-readable summary"
  value = <<-EOT
    Resources Created: ${length(local_file.configs)}
    Environment: ${var.environment}
    Output Directory: ${local.output_dir}
  EOT
}
```

### Resource Organization

1. **Use clear resource naming**:
```hcl
resource "local_file" "monitoring_config" {  # Clear, descriptive name
  filename = "./terraform-lab-output/monitoring.conf"
  content  = jsonencode(local.monitoring_settings)
}
```

2. **Group related resources with comments**:
```hcl
# ========================================================================
# MONITORING CONFIGURATION
# ========================================================================
resource "local_file" "monitoring_config" { ... }
resource "local_file" "alert_rules" { ... }
```

3. **Use locals for computed values**:
```hcl
locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  output_dir      = "./terraform-lab-output"
  timestamp       = timestamp()
}
```

### File Output Patterns

1. **Always use the standard output directory**:
```hcl
resource "local_file" "config" {
  filename = "./terraform-lab-output/config.json"  # Standard location
  content  = jsonencode(var.config)
}
```

2. **Create subdirectories for multiple files**:
```hcl
resource "local_file" "instance_configs" {
  count    = var.instance_count
  filename = "./terraform-lab-output/instances/instance-${count.index}.yaml"
  content  = yamlencode(local.instance_config[count.index])
}
```

### Exercise Validation

1. **Exercises auto-validate after successful apply in guided mode**
2. **Validation checks for state file with resources**
3. **Don't require specific resource counts - focus on concepts**

### Progress Tracking

1. **Progress is stored per-user in `%APPDATA%\TerraformLab\progress.json`**
2. **Never commit progress files to the repository**
3. **Each exercise awards 100 points upon completion**

### Testing Guidelines

1. **Test each exercise independently**:
```powershell
# Reset and test specific exercise
.\Start-TerraformLab.ps1 -ResetProgress
.\Start-TerraformLab.ps1 -Exercise "01-basics/01-hello-world" -SkipPrerequisites
```

2. **Verify cleanup works**:
```powershell
# In exercise directory
terraform destroy -auto-approve
Remove-Item -Path ".terraform", "terraform.tfstate*", "terraform-lab-output" -Recurse -Force
```

3. **Check template file handling**:
```powershell
terraform validate  # Should pass even with null variables
```

## PowerShell Integration Guidelines

### Comparing to PowerShell Concepts
Always provide PowerShell equivalents to help Windows administrators understand:

```hcl
# Terraform variable (like PowerShell parameter)
variable "instance_count" {
  type    = number
  default = 3
}

# Terraform local (like PowerShell variable)
locals {
  resource_prefix = "${var.project}-${var.environment}"
}

# Terraform resource (like PowerShell New-* cmdlet)
resource "local_file" "config" {
  filename = "config.json"
  content  = jsonencode(var.settings)
}

# Terraform data source (like PowerShell Get-* cmdlet)
data "local_file" "existing" {
  filename = "existing-config.json"
}

# Terraform output (like PowerShell Write-Output or return)
output "server_id" {
  value = resource.random_id.server.hex
}
```

### PowerShell Comparison Files
Each exercise should include a PowerShell comparison file (`terraform-vs-powershell-*.ps1`) that shows:

1. **Direct command mappings**:
   - `terraform init` → `Install-Module`
   - `terraform plan` → `-WhatIf`
   - `terraform apply` → Execute commands
   - `terraform destroy` → `Remove-*` cmdlets

2. **Concept mappings**:
   - Variables → Parameters
   - Locals → Variables
   - Resources → `New-*` cmdlets
   - Data sources → `Get-*` cmdlets
   - Outputs → `Write-Output` or `return`
   - Modules → PowerShell modules
   - Providers → PowerShell modules/snap-ins

3. **Pattern comparisons**:
   ```powershell
   # PowerShell: Imperative
   $config = Get-Content -Path "config.json" | ConvertFrom-Json
   $servers = @()
   foreach ($i in 1..3) {
       $servers += New-VM -Name "server-$i"
   }
   
   # Terraform: Declarative
   data "local_file" "config" {
     filename = "config.json"
   }
   resource "aws_instance" "servers" {
     count = 3
     name  = "server-${count.index + 1}"
   }
   ```

4. **Key differences to highlight**:
   - Declarative vs Imperative
   - State management vs Manual tracking
   - Idempotency vs Manual implementation
   - Dependency graphs vs Sequential execution

### Error Messages
Provide clear, actionable error messages:

```hcl
validation {
  condition     = var.instance_count > 0 && var.instance_count <= 10
  error_message = "Instance count must be between 1 and 10."
}
```

## Maintenance Checklist

### Before Adding New Exercises
- [ ] Follow the standard exercise structure
- [ ] Include PowerShell comparison examples
- [ ] Test with `terraform validate`
- [ ] Ensure template files handle null values
- [ ] Add to exercise list in Start-TerraformLab.ps1
- [ ] Set appropriate prerequisites
- [ ] Test exercise independently with -SkipPrerequisites

### Before Committing
- [ ] Run `terraform fmt` on all .tf files
- [ ] Ensure no state files are included
- [ ] Verify no progress.json files are included
- [ ] Clean up terraform-lab-output directories
- [ ] Test the exercise workflow end-to-end

### Regular Maintenance
- [ ] Update provider versions as needed
- [ ] Review and update PowerShell comparisons
- [ ] Test on fresh Windows installation
- [ ] Verify all exercises complete successfully
- [ ] Update documentation for any changes

## Contributing

When contributing new exercises or improvements:

1. Follow the existing naming patterns
2. Include comprehensive comments
3. Provide PowerShell equivalents
4. Test thoroughly before submitting
5. Update this BEST_PRACTICES.md if adding new patterns

## Support

For issues or questions:
1. Check the exercise README.md first
2. Try the "Reset this exercise" option
3. Use -SkipPrerequisites for testing
4. Review terraform.tfstate for debugging