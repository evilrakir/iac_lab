# Exercise: PowerShell Integration with Terraform

## 🎯 Learning Objectives

- Integrate PowerShell scripts with Terraform workflows
- Use Terraform to orchestrate PowerShell automation
- Combine declarative (Terraform) and imperative (PowerShell) approaches
- Leverage your existing PowerShell skills in Terraform environments

## 📋 Prerequisites

- Strong PowerShell skills (you have this! 🎉)
- Terraform installed
- Understanding of Terraform basics
- Windows environment or access to PowerShell

## 🚀 Getting Started

### Step 1: Navigate to the Exercise Directory

```powershell
cd 06-advanced/05-powershell-integration
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

### PowerShell + Terraform Integration Patterns

This exercise demonstrates how to:
- Execute PowerShell scripts from Terraform
- Use PowerShell for complex Windows configurations
- Pass Terraform variables to PowerShell scripts
- Handle PowerShell script outputs in Terraform
- Create hybrid automation workflows

### Integration with Your Background

Based on your experience with:
- **PowerShell automation frameworks**: We'll integrate with Terraform
- **Server provisioning and configuration**: Automate with Terraform + PowerShell
- **Windows infrastructure**: Combine both tools effectively
- **CI/CD pipelines**: Extend your existing workflows

## 📁 Files in This Exercise

- `main.tf` - Main Terraform configuration with PowerShell integration
- `variables.tf` - Variables for PowerShell scripts
- `outputs.tf` - Outputs from PowerShell execution
- `scripts/` - PowerShell scripts for various tasks
- `modules/` - Reusable PowerShell integration modules
- `README.md` - This file

## 🎯 Exercise Tasks

1. **Basic PowerShell Execution**: Run PowerShell scripts from Terraform
2. **Variable Passing**: Pass Terraform variables to PowerShell
3. **Output Handling**: Capture PowerShell outputs in Terraform
4. **Conditional Execution**: Run PowerShell based on Terraform conditions
5. **Error Handling**: Handle PowerShell errors in Terraform
6. **Complex Workflows**: Create multi-step PowerShell + Terraform workflows

## 💡 Integration Patterns

| Use Case | Terraform Approach | PowerShell Role |
|----------|-------------------|-----------------|
| Complex Windows Config | Terraform provisioner | PowerShell script |
| Data Processing | Terraform local-exec | PowerShell cmdlets |
| Service Configuration | Terraform resource | PowerShell DSC |
| Monitoring Setup | Terraform + PowerShell | Custom monitoring |
| User Management | Terraform + PowerShell | AD cmdlets |

## 🔗 Related Documentation

- [Terraform Local-Exec Provisioner](https://www.terraform.io/language/resources/provisioners/local-exec)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [Terraform Windows Provider](https://registry.terraform.io/providers/hashicorp/windows/latest/docs)
- [PowerShell DSC with Terraform](https://docs.microsoft.com/en-us/powershell/scripting/dsc/overview/overview)

## 🎓 Next Steps

After completing this exercise:
1. Integrate with your existing PowerShell automation
2. Create reusable PowerShell + Terraform modules
3. Extend your CI/CD pipelines with Terraform
4. Build hybrid automation frameworks

---

**Ready to combine PowerShell and Terraform! ⚡**
