# 🚀 Getting Started with Terraform Lab

## Quick Start (5 minutes)

### Step 1: Install Terraform (One-time setup)
You have three options:

#### Option A: Manual Download (No Admin)
1. Download from: https://www.terraform.io/downloads
2. Extract terraform.exe to a folder (e.g., C:\Tools\Terraform)
3. Add to your PATH or run from that folder

#### Option B: Chocolatey (Requires Admin)
```powershell
# Run as Administrator
choco install terraform
```

#### Option C: Use our installer (May require admin)
```powershell
# Run as Administrator if using Chocolatey
.\scripts\Install-LabTools.ps1 -Core
```

### Step 2: Create Your Workspace (No Admin)
```powershell
# From the lab root directory
.\Setup-Lab.ps1
```

This creates your personal workspace that's git-ignored.

### Step 3: Start Learning! (No Admin)
```powershell
# Enter your workspace
cd username-workspace

# Start the interactive lab
..\Start-TerraformLab.ps1
```

## 🔍 What Requires Administrator?

### ✅ NO Admin Required:
- Running Terraform commands
- All exercise files
- Creating workspaces
- Running the interactive lab
- Learning and practicing!

### ⚠️ Admin MAY Be Required For:
- Installing tools via Chocolatey
- Starting Docker Desktop (first time)
- Enabling Hyper-V
- Modifying system PATH

## 📚 Your First Exercise

Once setup is complete:

1. The interactive lab will guide you
2. Start with `01-basics/01-hello-world`
3. Each exercise has:
   - `main.tf` - The Terraform configuration
   - `interactive-guide.ps1` - Step-by-step walkthrough
   - `README.md` - Exercise documentation

## 🆘 Troubleshooting

### "Terraform not found"
- Make sure terraform.exe is in your PATH
- Or specify full path: `C:\Tools\Terraform\terraform.exe init`

### "Cannot run script"
```powershell
# Allow script execution for current session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### "Access denied" 
- Most exercises don't need admin
- Check if you're trying to modify system files

## 💡 Tips for Windows Admins

1. **Think of Terraform like PowerShell DSC** - Declarative configuration
2. **terraform plan = -WhatIf** - Preview changes
3. **State file = MOF file** - Tracks current state
4. **Providers = PowerShell Modules** - Extend functionality

## 📞 Getting Help

- **Interactive hints**: Built into the lab
- **Documentation**: Each exercise has a README
- **Environment check**: `.\Quick-Check.ps1`
- **GitHub Issues**: https://github.com/evilrakir/iac_lab

---

Ready? Run `.\Setup-Lab.ps1` to begin your journey!