# Exercise: Windows Infrastructure with Terraform

## 🎯 Learning Objectives

- Deploy Windows infrastructure using Terraform
- Integrate Terraform with PowerShell automation
- Manage Windows-specific resources (IIS, Windows Services, Registry)
- Understand how Terraform complements your existing PowerShell skills

## 📋 Prerequisites

- Windows machine or Windows VM
- Terraform installed
- PowerShell 5.1 or later
- Administrative privileges (for some operations)

## 🚀 Getting Started

### Step 1: Navigate to the Exercise Directory

```powershell
cd 02-providers/05-windows-provider
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

### Windows Provider Capabilities

The Windows provider allows Terraform to manage:
- Windows Services
- Windows Registry keys and values
- Windows Event Logs
- Windows Scheduled Tasks
- Windows Shares
- Windows Users and Groups

### Integration with PowerShell

This exercise demonstrates how to:
- Use Terraform to provision Windows infrastructure
- Integrate PowerShell scripts for complex configurations
- Combine declarative (Terraform) and imperative (PowerShell) approaches
- Maintain Windows infrastructure as code

## 📁 Files in This Exercise

- `main.tf` - Main Terraform configuration for Windows resources
- `variables.tf` - Windows-specific variables
- `outputs.tf` - Outputs for Windows resources
- `scripts/` - PowerShell scripts for complex configurations
- `README.md` - This file

## 🎯 Exercise Tasks

1. **Windows Service Management**: Create and configure Windows services
2. **Registry Management**: Manage Windows Registry keys and values
3. **PowerShell Integration**: Execute PowerShell scripts from Terraform
4. **Windows User Management**: Create and configure Windows users
5. **Scheduled Tasks**: Create Windows scheduled tasks

## 💡 PowerShell to Terraform Mapping

| PowerShell Concept | Terraform Equivalent |
|-------------------|---------------------|
| `New-Service` | `windows_service` resource |
| `Set-ItemProperty` | `windows_registry` resource |
| `New-LocalUser` | `windows_user` resource |
| `Register-ScheduledTask` | `windows_scheduled_task` resource |
| `New-SmbShare` | `windows_share` resource |

## 🔗 Related Documentation

- [Windows Provider Documentation](https://registry.terraform.io/providers/hashicorp/windows/latest/docs)
- [PowerShell Integration with Terraform](https://www.terraform.io/language/resources/provisioners/local-exec)
- [Windows Infrastructure as Code Best Practices](https://docs.microsoft.com/en-us/azure/devops/pipelines/infrastructure/infrastructure-as-code)

## 🎓 Next Steps

After completing this exercise:
1. Explore more Windows provider resources
2. Create reusable Windows modules
3. Integrate with your existing PowerShell automation
4. Consider hybrid approaches (Terraform + PowerShell)

---

**Ready to manage Windows infrastructure with Terraform! 🪟**
