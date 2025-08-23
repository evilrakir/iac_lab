#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive guide for OpenStack Provider Setup
.DESCRIPTION
    Walks through configuring the OpenStack provider and testing connectivity
#>

param([switch]$AutoApprove)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n➤ $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "  ⚠️  $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "  ℹ️  $Message" -ForegroundColor Gray
}

# Header
Clear-Host
Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║   OPENSTACK PROVIDER SETUP - INTERACTIVE GUIDE                  ║
║   Exercise 1: Authentication and Resource Discovery             ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`nThis guide will help you configure the OpenStack provider and test connectivity."

# Check if we're in the right directory
if (-not (Test-Path "main.tf")) {
    Write-Warning "main.tf not found. Make sure you're in the 03-openstack/01-provider-setup directory"
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne 'y') { exit 1 }
}

# Step 1: Check OpenStack credentials
Write-Step "Checking OpenStack credentials"

$osVars = @{
    "OS_AUTH_URL" = $env:OS_AUTH_URL
    "OS_USERNAME" = $env:OS_USERNAME
    "OS_PASSWORD" = if ($env:OS_PASSWORD) { "***SET***" } else { $null }
    "OS_PROJECT_NAME" = $env:OS_PROJECT_NAME
    "OS_USER_DOMAIN_NAME" = $env:OS_USER_DOMAIN_NAME
    "OS_PROJECT_DOMAIN_NAME" = $env:OS_PROJECT_DOMAIN_NAME
    "OS_REGION_NAME" = $env:OS_REGION_NAME
}

$hasCredentials = $false
foreach ($var in $osVars.GetEnumerator()) {
    if ($var.Value) {
        Write-Success "$($var.Key): $($var.Value)"
        $hasCredentials = $true
    } else {
        Write-Info "$($var.Key): Not set"
    }
}

if (-not $hasCredentials) {
    Write-Warning "No OpenStack environment variables detected"
    Write-Host "`nYou can either:"
    Write-Host "1. Set environment variables (recommended)"
    Write-Host "2. Modify the provider block in main.tf with your credentials"
    Write-Host "`nFor environment variables, run:"
    Write-Host @"
`$env:OS_AUTH_URL = "https://your-openstack.example.com:5000/v3"
`$env:OS_USERNAME = "your-username"
`$env:OS_PASSWORD = "your-password"
`$env:OS_PROJECT_NAME = "your-project"
`$env:OS_USER_DOMAIN_NAME = "Default"
`$env:OS_PROJECT_DOMAIN_NAME = "Default"
"@ -ForegroundColor Yellow
    
    $continue = Read-Host "`nDo you want to continue anyway? (y/N)"
    if ($continue -ne 'y') { 
        Write-Host "Set your credentials and run this guide again." -ForegroundColor Cyan
        exit 0 
    }
}

# Step 2: Initialize Terraform
Write-Step "Initializing Terraform"

if (Test-Path ".terraform") {
    Write-Info "Terraform already initialized"
} else {
    try {
        $initOutput = terraform init 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Terraform initialized successfully"
        } else {
            Write-Warning "Terraform init had warnings: $initOutput"
        }
    } catch {
        Write-Host "❌ Terraform init failed: $_" -ForegroundColor Red
        exit 1
    }
}

# Step 3: Validate configuration
Write-Step "Validating Terraform configuration"

try {
    $validateOutput = terraform validate 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Configuration is valid"
    } else {
        Write-Host "❌ Validation failed: $validateOutput" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Validation error: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Plan the deployment
Write-Step "Creating Terraform plan"

Write-Info "This will attempt to connect to OpenStack and discover resources..."

try {
    $planOutput = terraform plan -detailed-exitcode 2>&1
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Success "Plan completed - no changes needed"
    } elseif ($exitCode -eq 2) {
        Write-Success "Plan completed - changes detected"
        Write-Info "The plan will query OpenStack for available resources"
    } else {
        Write-Host "❌ Planning failed:" -ForegroundColor Red
        Write-Host $planOutput -ForegroundColor Red
        
        Write-Host "`n🔍 Common issues:" -ForegroundColor Yellow
        Write-Host "• Check your OpenStack credentials"
        Write-Host "• Verify the auth_url is correct"
        Write-Host "• Ensure your user has proper permissions"
        Write-Host "• Check network connectivity to OpenStack API"
        
        exit 1
    }
} catch {
    Write-Host "❌ Planning error: $_" -ForegroundColor Red
    exit 1
}

# Step 5: Apply the configuration
Write-Step "Applying Terraform configuration"

Write-Info "This will connect to OpenStack and output resource information"

if (-not $AutoApprove) {
    $apply = Read-Host "Apply the configuration? (y/N)"
    if ($apply -ne 'y') { 
        Write-Host "Skipping apply step" -ForegroundColor Yellow
        exit 0
    }
}

try {
    $applyOutput = terraform apply -auto-approve 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Configuration applied successfully!"
    } else {
        Write-Host "❌ Apply failed: $applyOutput" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Apply error: $_" -ForegroundColor Red
    exit 1
}

# Step 6: Show outputs
Write-Step "Displaying OpenStack resource information"

try {
    $outputs = terraform output -json | ConvertFrom-Json
    
    if ($outputs.auth_scope) {
        Write-Host "`n🔐 Authentication Scope:" -ForegroundColor Green
        $scope = $outputs.auth_scope.value
        Write-Host "  Project: $($scope.project_name)" -ForegroundColor White
        Write-Host "  User: $($scope.user_name)" -ForegroundColor White
        Write-Host "  Roles: $($scope.roles -join ', ')" -ForegroundColor White
    }
    
    if ($outputs.available_resources) {
        Write-Host "`n🔍 Available Resources:" -ForegroundColor Green
        $resources = $outputs.available_resources.value
        
        if ($resources.ubuntu_image) {
            Write-Host "`n  Ubuntu Image:" -ForegroundColor Cyan
            Write-Host "    Name: $($resources.ubuntu_image.name)" -ForegroundColor White
            Write-Host "    ID: $($resources.ubuntu_image.id)" -ForegroundColor Gray
            Write-Host "    Size: $([math]::Round($resources.ubuntu_image.size / 1GB, 2)) GB" -ForegroundColor White
        }
        
        if ($resources.small_flavor) {
            Write-Host "`n  Small Flavor:" -ForegroundColor Cyan
            Write-Host "    Name: $($resources.small_flavor.name)" -ForegroundColor White
            Write-Host "    vCPUs: $($resources.small_flavor.vcpus)" -ForegroundColor White
            Write-Host "    RAM: $($resources.small_flavor.ram) MB" -ForegroundColor White
            Write-Host "    Disk: $($resources.small_flavor.disk) GB" -ForegroundColor White
        }
        
        if ($resources.external_network) {
            Write-Host "`n  External Network:" -ForegroundColor Cyan
            Write-Host "    Name: $($resources.external_network.name)" -ForegroundColor White
            Write-Host "    ID: $($resources.external_network.id)" -ForegroundColor Gray
        }
        
        if ($resources.internal_network) {
            Write-Host "`n  Internal Network:" -ForegroundColor Cyan
            Write-Host "    Name: $($resources.internal_network.name)" -ForegroundColor White
            Write-Host "    ID: $($resources.internal_network.id)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Warning "Could not parse terraform outputs: $_"
}

# Summary
Write-Host "`n" -NoNewline
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ OPENSTACK PROVIDER SETUP COMPLETE!                         ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n🎉 Congratulations! You have successfully:" -ForegroundColor Cyan
Write-Host "  • Configured the OpenStack Terraform provider"
Write-Host "  • Established connectivity to your OpenStack cloud"
Write-Host "  • Discovered available images, flavors, and networks"
Write-Host "  • Validated your authentication and permissions"

Write-Host "`n🚀 Next Steps:" -ForegroundColor Yellow
Write-Host "  • Move to Exercise 2: Basic VM Deployment"
Write-Host "  • cd ../02-basic-vm"
Write-Host "  • ./interactive-guide.ps1"

Write-Host "`n💡 What You Learned:" -ForegroundColor Cyan
Write-Host "  • OpenStack provider authentication methods"
Write-Host "  • Using data sources for resource discovery"
Write-Host "  • Testing cloud connectivity with Terraform"
Write-Host "  • Understanding OpenStack resource hierarchy"

$nextExercise = Read-Host "`nProceed to Exercise 2? (Y/n)"
if ($nextExercise -ne 'n') {
    if (Test-Path "../02-basic-vm/interactive-guide.ps1") {
        Write-Host "`nMoving to Exercise 2..." -ForegroundColor Green
        Set-Location "../02-basic-vm"
        & "./interactive-guide.ps1"
    } else {
        Write-Host "Exercise 2 not found. Please navigate manually." -ForegroundColor Yellow
    }
}