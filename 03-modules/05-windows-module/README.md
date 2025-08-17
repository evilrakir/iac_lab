# Exercise: Windows Infrastructure Module

## 🎯 Learning Objectives

- Create reusable Windows infrastructure modules
- Package Windows automation into Terraform modules
- Build modules for common Windows patterns
- Understand how to modularize Windows infrastructure

## 📋 Prerequisites

- Windows infrastructure experience (you have this! 🎉)
- Terraform basics understanding
- PowerShell skills
- Windows environment access

## 🚀 Getting Started

### Step 1: Navigate to the Exercise Directory

```powershell
cd 03-modules/05-windows-module
```

### Step 2: Initialize Terraform

```powershell
terraform init
```

### Step 3: Plan Your Changes

```powershell
terraform plan
```

### Step 4: Apply Your Configuration

```powershell
terraform apply
```

## 🔍 What You'll Learn

### Windows Module Patterns

This exercise demonstrates how to:
- Create reusable Windows infrastructure modules
- Package PowerShell automation into modules
- Build modules for common Windows patterns
- Share Windows modules across teams
- Version and maintain Windows modules

### Integration with Your Background

Based on your experience with:
- **Windows Server**: We'll create modules for Windows infrastructure
- **PowerShell automation**: Package your scripts into modules
- **Server provisioning**: Automate with reusable modules
- **Infrastructure management**: Create standardized patterns

## 📁 Files in This Exercise

- `main.tf` - Main Terraform configuration using Windows modules
- `variables.tf` - Variables for Windows modules
- `outputs.tf` - Outputs from Windows modules
- `modules/` - Reusable Windows modules
- `examples/` - Example usage of Windows modules
- `README.md` - This file

## 🎯 Exercise Tasks

1. **Basic Windows Module**: Create a simple Windows module
2. **Module Variables**: Define inputs and outputs for Windows modules
3. **PowerShell Integration**: Integrate PowerShell scripts into modules
4. **Module Composition**: Combine multiple Windows modules
5. **Module Testing**: Test Windows modules with different configurations
6. **Module Documentation**: Document Windows modules for team use

## 💡 Windows Module Patterns

| Windows Pattern | Module Approach |
|-----------------|-----------------|
| User Management | Windows user/group module |
| Service Configuration | Windows service module |
| Registry Management | Windows registry module |
| File System | Windows file/directory module |
| Scheduled Tasks | Windows task module |

## 🔗 Related Documentation

- [Terraform Modules Documentation](https://www.terraform.io/language/modules)
- [Windows Provider Documentation](https://registry.terraform.io/providers/hashicorp/windows/latest/docs)
- [PowerShell with Terraform](https://www.terraform.io/language/resources/provisioners/local-exec)
- [Module Best Practices](https://www.terraform.io/language/modules/develop)

## 🎓 Next Steps

After completing this exercise:
1. Create modules for your common Windows patterns
2. Share modules with your team
3. Publish modules to Terraform Registry
4. Integrate with your existing automation

---

**Ready to modularize your Windows infrastructure! 🪟**
