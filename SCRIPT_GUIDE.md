# Terraform Lab Scripts Guide

## 🎯 Main Scripts (Use These)

### `Start-TerraformLab.ps1`
**Purpose**: Main interactive lab runner  
**Use**: Start learning exercises with guided mode  
```powershell
.\Start-TerraformLab.ps1
```

### `Setup-Lab.ps1` 
**Purpose**: Simple workspace setup (lightweight alternative to Initialize-UserWorkspace)  
**Use**: Quick setup without all the copying  
```powershell
.\Setup-Lab.ps1
```

### `Initialize-UserWorkspace.ps1`
**Purpose**: Full workspace initialization with file copying  
**Use**: Complete workspace setup for new users  
```powershell
.\Initialize-UserWorkspace.ps1
```

## 🔧 Installation Scripts

### `Install-TerraformUser.ps1`
**Purpose**: Install Terraform for current user (no admin required)  
**Use**: One-time Terraform installation  
```powershell
.\Install-TerraformUser.ps1
```

### `scripts\Install-LabTools.ps1`
**Purpose**: Install all lab tools (Terraform, Docker, etc.)  
**Use**: Complete tool installation  
```powershell
.\scripts\Install-LabTools.ps1
```

## 📊 Utility Scripts (in utilities/ folder)

### `utilities\Quick-Check.ps1`
**Purpose**: Quick environment verification  
**Use**: Check if tools are installed correctly  
```powershell
.\utilities\Quick-Check.ps1
```

### `utilities\Test-InteractiveLab.ps1`
**Purpose**: Automated testing of lab functionality  
**Use**: For maintainers to verify lab works  
```powershell
.\utilities\Test-InteractiveLab.ps1
```

### `utilities\Demo-InteractiveLab.ps1`
**Purpose**: Demo script showing lab features  
**Use**: For instructors to demonstrate capabilities  
```powershell
.\utilities\Demo-InteractiveLab.ps1
```

## ❓ Which Script Should I Use?

### For Students Starting Fresh:
1. `Install-TerraformUser.ps1` - Install Terraform (once)
2. `Initialize-UserWorkspace.ps1` - Set up your workspace (once)
3. `Start-TerraformLab.ps1` - Start learning!

### For Quick Start (Terraform already installed):
1. `Setup-Lab.ps1` - Minimal workspace setup
2. `Start-TerraformLab.ps1` - Start learning!

### For Troubleshooting:
- `utilities\Quick-Check.ps1` - Verify environment

## 🗂️ Script Redundancy Issues

### Keep These:
- `Start-TerraformLab.ps1` - Main lab runner
- `Initialize-UserWorkspace.ps1` OR `Setup-Lab.ps1` - Choose one approach

### Consider Removing/Consolidating:
- Either `Initialize-UserWorkspace.ps1` or `Setup-Lab.ps1` (they overlap)
- The workspace creation could be integrated into `Start-TerraformLab.ps1`

## 📝 Recommendation

The cleanest approach would be:
1. **One main script**: `Start-TerraformLab.ps1` that handles:
   - Workspace creation on first run
   - Session management
   - Exercise selection
   - Progress tracking

2. **One installer**: `Install-TerraformUser.ps1` for tools

3. **Utilities folder**: For testing/demo scripts

This would eliminate confusion about which script to use!