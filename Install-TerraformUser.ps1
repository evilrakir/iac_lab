# Install-TerraformUser.ps1 - Install Terraform without admin rights
param(
    [string]$Version = "1.5.7",
    [string]$InstallPath = "$env:LOCALAPPDATA\terraform"
)

Write-Host "`n=== Installing Terraform (User Mode) ===" -ForegroundColor Cyan
Write-Host "No administrator rights required!" -ForegroundColor Green

# Create install directory
if (-not (Test-Path $InstallPath)) {
    Write-Host "Creating directory: $InstallPath" -ForegroundColor Gray
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

# Download URL
$downloadUrl = "https://releases.hashicorp.com/terraform/${Version}/terraform_${Version}_windows_amd64.zip"
$zipPath = Join-Path $env:TEMP "terraform_${Version}.zip"
$exePath = Join-Path $InstallPath "terraform.exe"

# Check if already installed
if (Test-Path $exePath) {
    Write-Host "Terraform already installed at: $exePath" -ForegroundColor Yellow
    $currentVersion = & $exePath version 2>$null
    Write-Host "Current version: $currentVersion" -ForegroundColor Gray
    
    $overwrite = Read-Host "Reinstall? (y/N)"
    if ($overwrite -ne 'y') {
        Write-Host "Installation cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Download
Write-Host "Downloading Terraform $Version..." -ForegroundColor Cyan
Write-Host "URL: $downloadUrl" -ForegroundColor Gray

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "✅ Download complete" -ForegroundColor Green
} catch {
    Write-Host "❌ Download failed: $_" -ForegroundColor Red
    exit 1
}

# Extract
Write-Host "Extracting..." -ForegroundColor Cyan
try {
    Expand-Archive -Path $zipPath -DestinationPath $InstallPath -Force
    Write-Host "✅ Extraction complete" -ForegroundColor Green
} catch {
    Write-Host "❌ Extraction failed: $_" -ForegroundColor Red
    exit 1
}

# Clean up zip
Remove-Item $zipPath -Force

# Test installation
Write-Host "`nTesting installation..." -ForegroundColor Cyan
$version = & $exePath version 2>$null
if ($?) {
    Write-Host "✅ Terraform installed successfully!" -ForegroundColor Green
    Write-Host "   Version: $version" -ForegroundColor Gray
} else {
    Write-Host "❌ Installation test failed" -ForegroundColor Red
    exit 1
}

# Add to user PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$InstallPath*") {
    Write-Host "`nAdding to user PATH..." -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallPath", "User")
    Write-Host "✅ Added to PATH" -ForegroundColor Green
    Write-Host "   ⚠️  Restart your terminal for PATH changes to take effect" -ForegroundColor Yellow
} else {
    Write-Host "✅ Already in PATH" -ForegroundColor Green
}

# Create alias for current session
Write-Host "`nFor current session, you can use:" -ForegroundColor Cyan
Write-Host "  $exePath" -ForegroundColor White
Write-Host "Or create an alias:" -ForegroundColor Gray
Write-Host "  Set-Alias terraform '$exePath'" -ForegroundColor White

# Set alias for current session
Set-Alias -Name terraform -Value $exePath -Scope Global -Force
Write-Host "`n✅ Alias set for current session" -ForegroundColor Green

Write-Host "`n=== Installation Complete! ===" -ForegroundColor Green
Write-Host "You can now use 'terraform' command" -ForegroundColor Cyan
Write-Host ""