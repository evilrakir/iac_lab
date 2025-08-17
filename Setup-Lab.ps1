# Setup-Lab.ps1 - Simple lab setup without admin requirements
param(
    [string]$WorkspaceName = "$env:USERNAME-workspace",
    [switch]$Reset
)

Write-Host ""
Write-Host "=== TERRAFORM LAB SETUP ===" -ForegroundColor Cyan
Write-Host "Modern Infrastructure as Code for Windows Admins" -ForegroundColor Yellow
Write-Host ""

# Check if we need admin (we don't for basic setup)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "Running as Administrator" -ForegroundColor Green
} else {
    Write-Host "Running as regular user (this is fine!)" -ForegroundColor Green
}

# Create workspace
$workspacePath = Join-Path $PSScriptRoot $WorkspaceName

if (Test-Path $workspacePath) {
    if ($Reset) {
        Write-Host "Removing existing workspace..." -ForegroundColor Yellow
        Remove-Item -Path $workspacePath -Recurse -Force
    } else {
        Write-Host "Workspace already exists: $workspacePath" -ForegroundColor Yellow
        $use = Read-Host "Use existing workspace? (Y/n)"
        if ($use -eq 'n') { exit }
    }
}

if (-not (Test-Path $workspacePath)) {
    Write-Host "Creating workspace: $WorkspaceName" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $workspacePath -Force | Out-Null
    
    # Copy exercise structure
    $dirs = @("01-basics", "07-containers", "08-integrations")
    foreach ($dir in $dirs) {
        $src = Join-Path $PSScriptRoot $dir
        if (Test-Path $src) {
            Write-Host "  Copying $dir exercises..." -ForegroundColor Gray
            Copy-Item -Path $src -Destination $workspacePath -Recurse -Force
        }
    }
    
    Write-Host "Workspace created successfully!" -ForegroundColor Green
}

Write-Host ""
Write-Host "WHAT REQUIRES ADMIN?" -ForegroundColor Yellow
Write-Host "-------------------" -ForegroundColor Gray
Write-Host "Nothing for basic Terraform exercises!" -ForegroundColor Green
Write-Host ""
Write-Host "Only needed for:" -ForegroundColor Gray
Write-Host "  - Installing tools via Chocolatey" -ForegroundColor Gray
Write-Host "  - Starting Hyper-V based services" -ForegroundColor Gray
Write-Host "  - Modifying system PATH" -ForegroundColor Gray
Write-Host ""
Write-Host "You can do all exercises without admin!" -ForegroundColor Green

Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. cd $WorkspaceName" -ForegroundColor White
Write-Host "2. ..\Start-TerraformLab.ps1" -ForegroundColor White
Write-Host ""