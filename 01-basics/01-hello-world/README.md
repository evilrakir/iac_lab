# Exercise 1: Hello World - Your First Terraform Configuration

## 🎯 Learning Objectives

- Understand basic Terraform syntax and structure
- Learn the Terraform workflow (init, plan, apply, destroy)
- Create your first infrastructure resource
- Compare Terraform to PowerShell automation concepts

## 📋 Prerequisites

- Terraform installed (download from [terraform.io](https://www.terraform.io/downloads))
- Basic understanding of infrastructure concepts
- Familiarity with PowerShell (you already have this! 🎉)

## 🚀 Getting Started

### Step 1: Navigate to the Exercise Directory

```powershell
cd 01-basics/01-hello-world
```

### Step 2: Initialize Terraform

```powershell
terraform init
```

This downloads the required providers (like installing PowerShell modules).

### Step 3: Plan Your Changes

```powershell
terraform plan
```

This shows what Terraform will create (like `-WhatIf` in PowerShell).

### Step 4: Apply Your Configuration

```powershell
terraform apply
```

This creates the actual resources (like running your PowerShell script).

### Step 5: Clean Up

```powershell
terraform destroy
```

This removes the resources (like cleanup scripts in PowerShell).

## 🔍 What You'll Learn

### Terraform vs PowerShell Comparison

| Concept | PowerShell | Terraform |
|---------|------------|-----------|
| Script execution | `.\script.ps1` | `terraform apply` |
| Preview changes | `-WhatIf` | `terraform plan` |
| Configuration | `.ps1` files | `.tf` files |
| State management | Manual tracking | Automatic state files |
| Idempotency | Manual implementation | Built-in |

### Key Terraform Concepts

1. **Providers**: Like PowerShell modules (AWS, Azure, local, etc.)
2. **Resources**: The infrastructure objects you want to create
3. **State**: Terraform's memory of what it has created
4. **Configuration**: HCL (HashiCorp Configuration Language) files

## 📁 Files in This Exercise

- `main.tf` - Main Terraform configuration
- `variables.tf` - Variable definitions
- `outputs.tf` - Output values
- `README.md` - This file

## 🎯 Exercise Tasks

1. **Basic Resource Creation**: Create a simple local file
2. **Variable Usage**: Use variables to make your configuration flexible
3. **Output Values**: Display information about created resources
4. **State Inspection**: Understand how Terraform tracks resources

## 💡 Tips for PowerShell Users

- Think of Terraform as "PowerShell for infrastructure"
- `terraform plan` is like `-WhatIf` but more powerful
- Terraform state is like a database of your infrastructure
- HCL syntax is simpler than PowerShell but more structured

## 🔗 Related Documentation

- [Terraform Language Documentation](https://www.terraform.io/language)
- [Local Provider Documentation](https://registry.terraform.io/providers/hashicorp/local/latest/docs)
- [Terraform CLI Commands](https://www.terraform.io/cli/commands)

## 🎓 Next Steps

After completing this exercise:
1. Try modifying the configuration and see what changes
2. Experiment with different resource types
3. Move to the next exercise: Variables and Locals

---

**Ready to start? Let's create some infrastructure! 🏗️**
