# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Terraform Learning Lab designed as a hands-on educational resource for learning Infrastructure as Code (IaC) with Terraform. The lab progresses from basic concepts to advanced topics, with exercises tailored for users with PowerShell and DevOps backgrounds.

## Terraform Commands

### Core Terraform Workflow
```bash
# Initialize Terraform (download providers, modules)
terraform init

# Preview changes without applying
terraform plan

# Apply configuration
terraform apply

# Destroy all resources
terraform destroy

# Validate configuration syntax
terraform validate

# Format configuration files
terraform fmt

# Show current state
terraform show
```

### Working with Specific Resources
```bash
# Apply only specific resources
terraform apply -target=resource_type.resource_name

# Destroy specific resources  
terraform destroy -target=resource_type.resource_name

# Import existing infrastructure
terraform import resource_type.resource_name resource_id

# Refresh state
terraform refresh
```

### State Management
```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show resource_type.resource_name

# Move resources in state
terraform state mv source_address destination_address

# Remove from state without destroying
terraform state rm resource_type.resource_name
```

## Project Structure

The lab follows a progressive structure from basics to advanced:

- **01-basics/**: Core Terraform concepts using local provider (no cloud required)
  - Variables, outputs, data sources, resources
  - Each exercise includes PowerShell comparison examples
  
- **02-providers/**: Working with different infrastructure providers
  - Local provider for learning without cloud costs
  - AWS, Azure, GCP basics
  - Windows-specific provider configurations
  
- **03-modules/**: Creating reusable Terraform modules
  - Module structure, variables, outputs
  - Module sources and registry usage
  - Windows infrastructure modules
  
- **04-state/**: State management and collaboration
  - Local vs remote state
  - State locking, workspaces
  - GitOps workflow integration
  
- **05-best-practices/**: Production patterns
  - Project organization, naming conventions
  - Security, cost optimization
  - Monitoring infrastructure integration
  
- **06-advanced/**: Advanced Terraform features
  - Dynamic blocks, conditionals, functions
  - Custom providers
  - PowerShell integration patterns

## Architecture Patterns

### Module Structure
Terraform modules in this lab follow standard patterns:
- `main.tf`: Primary resource definitions
- `variables.tf`: Input variable definitions with validation
- `outputs.tf`: Output values
- `versions.tf`: Provider and Terraform version constraints

### State Management Architecture
- Exercises progress from local state to remote backends
- Remote state patterns include S3/Azure Storage/GCS backends
- GitOps workflows demonstrate state management in CI/CD

### Provider Configuration
- Each provider exercise includes authentication setup
- Environment-specific configurations using workspaces
- Provider version pinning for reproducibility

## Key Concepts for Development

### Variable Precedence
1. Environment variables (TF_VAR_*)
2. terraform.tfvars file
3. *.auto.tfvars files (alphabetical order)
4. -var and -var-file options
5. Variable defaults

### Resource Dependencies
- Implicit dependencies via resource references
- Explicit dependencies using `depends_on`
- Data source dependencies for existing infrastructure

### PowerShell Integration Points
- Local-exec provisioner for PowerShell scripts
- External data sources using PowerShell
- Terraform outputs consumed by PowerShell automation
- Windows-specific resource management

### Testing Approaches
- `terraform plan` for validation
- `terraform validate` for syntax checking
- Integration with existing PowerShell test frameworks
- Cost estimation before applying changes