# Administrator Notes for Terraform Lab

## What DOESN'T Require Admin

✅ **Most of the lab!** Including:
- Running Terraform commands (once installed)
- All exercise files and configurations
- Creating and using workspaces
- Running the interactive lab system
- PowerShell scripts (except installers)

## What DOES Require Admin

### 1. Tool Installation (One-time)

#### Option A: Manual Install (NO ADMIN NEEDED)
```powershell
# Download Terraform manually from:
# https://www.terraform.io/downloads

# Extract to a user folder like:
# C:\Users\%USERNAME%\Tools\terraform\

# Add to PATH or use full path:
C:\Users\YourName\Tools\terraform\terraform.exe init
```

#### Option B: Chocolatey (ADMIN REQUIRED)
```powershell
# Run as Administrator
choco install terraform
choco install docker-desktop  # Optional
choco install minikube        # Optional
```

### 2. Docker Desktop (Optional)

- First installation requires admin
- Starting the service first time requires admin
- After setup, can run as regular user

### 3. Hyper-V Features (Optional)

- Only needed for Hyper-V based Minikube
- Can use Docker driver instead (no Hyper-V needed)

## Recommended Approach

### For Learning Terraform Basics:
1. **No admin needed!** Download Terraform manually
2. Use local provider exercises (01-basics)
3. Learn core concepts without cloud/containers

### For Container/K8s Exercises:
1. Install Docker Desktop (one-time admin)
2. Or use cloud-based Kubernetes (no local admin)
3. Or skip to cloud provider exercises

## Quick Test Without Admin

```powershell
# Check what's already available
.\Quick-Check.ps1

# Try to run exercises with what you have
cd 01-basics\01-hello-world
# Use full path if terraform not in PATH
C:\Path\To\terraform.exe init
```

## Firewall/Proxy Issues

If downloads fail due to corporate firewall:
1. Download files manually from browser
2. Place in expected locations
3. Run scripts with -SkipDownload flags

## Summary

**80% of the lab works without admin!** Only initial tool installation typically needs elevation. After that, you're good to go as a regular user.