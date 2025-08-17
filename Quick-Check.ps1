# Quick environment check for Terraform Lab
# Verifies that required tools are available

Write-Host ""
Write-Host "=== TERRAFORM LAB ENVIRONMENT CHECK ===" -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# Check Terraform
Write-Host "Checking Terraform..." -ForegroundColor Yellow
$terraformPath = "C:\Tools\Terraform\terraform.exe"
if (Test-Path $terraformPath) {
    Write-Host "[PASS] Terraform found at $terraformPath" -ForegroundColor Green
    try {
        $version = & $terraformPath version
        Write-Host "       Version: $($version[0])" -ForegroundColor Gray
    } catch {
        Write-Host "[WARN] Could not get Terraform version" -ForegroundColor Yellow
    }
} else {
    Write-Host "[FAIL] Terraform not found at $terraformPath" -ForegroundColor Red
    $allGood = $false
}

# Check PowerShell version
Write-Host ""
Write-Host "Checking PowerShell..." -ForegroundColor Yellow
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Write-Host "[PASS] PowerShell version $($PSVersionTable.PSVersion) is supported" -ForegroundColor Green
} else {
    Write-Host "[FAIL] PowerShell 5.1+ required, found $($PSVersionTable.PSVersion)" -ForegroundColor Red
    $allGood = $false
}

# Check lab structure
Write-Host ""
Write-Host "Checking lab structure..." -ForegroundColor Yellow
$requiredDirs = @("01-basics\01-hello-world", "01-basics\02-variables")
foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        Write-Host "[PASS] Found required directory: $dir" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Missing required directory: $dir" -ForegroundColor Red
        $allGood = $false
    }
}

# Check main lab script
Write-Host ""
Write-Host "Checking lab scripts..." -ForegroundColor Yellow
if (Test-Path "Start-TerraformLab.ps1") {
    Write-Host "[PASS] Main lab script found" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Start-TerraformLab.ps1 not found" -ForegroundColor Red
    $allGood = $false
}

# Optional tools check
Write-Host ""
Write-Host "Checking optional tools..." -ForegroundColor Yellow

# Check Docker
try {
    $dockerVersion = docker version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OPTIONAL] Docker is available and running" -ForegroundColor Green
    } else {
        Write-Host "[OPTIONAL] Docker not running (not required for basic exercises)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[OPTIONAL] Docker not found (not required for basic exercises)" -ForegroundColor Yellow
}

# Check kubectl
try {
    $kubectl = Get-Command kubectl -ErrorAction SilentlyContinue
    if ($kubectl) {
        Write-Host "[OPTIONAL] kubectl found (for Kubernetes exercises)" -ForegroundColor Green
    } else {
        Write-Host "[OPTIONAL] kubectl not found (only needed for Kubernetes exercises)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[OPTIONAL] kubectl not found (only needed for Kubernetes exercises)" -ForegroundColor Yellow
}

# Final status
Write-Host ""
Write-Host "=== ENVIRONMENT CHECK COMPLETE ===" -ForegroundColor Cyan
if ($allGood) {
    Write-Host ""
    Write-Host "Ready to start the Terraform Learning Lab!" -ForegroundColor Green
    Write-Host "Run: .\Start-TerraformLab.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Some issues found. Please resolve the [FAIL] items above." -ForegroundColor Red
    Write-Host ""
}