#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Automated installer for Terraform Lab tools
.DESCRIPTION
    Installs missing tools detected by Check-Environment.ps1
.PARAMETER Core
    Install only core required tools (Terraform, Git)
.PARAMETER Containers
    Install container tools (Docker Desktop, etc.)
.PARAMETER Kubernetes
    Install Kubernetes tools (kubectl, minikube, helm)
.PARAMETER Cloud
    Install cloud provider CLIs
.PARAMETER All
    Install all recommended tools
.EXAMPLE
    .\Install-LabTools.ps1 -Core
.EXAMPLE
    .\Install-LabTools.ps1 -All
#>
[CmdletBinding()]
param(
    [switch]$Core,
    [switch]$Containers,
    [switch]$Kubernetes,
    [switch]$Cloud,
    [switch]$ConfigManagement,
    [switch]$All,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# If no specific category selected, default to Core
if (-not ($Core -or $Containers -or $Kubernetes -or $Cloud -or $ConfigManagement -or $All)) {
    $Core = $true
}

if ($All) {
    $Core = $Containers = $Kubernetes = $Cloud = $ConfigManagement = $true
}

function Write-Step { 
    Write-Host "`n➤ $($args -join ' ')" -ForegroundColor Cyan 
}

function Write-Success { 
    Write-Host "  ✅ $($args -join ' ')" -ForegroundColor Green 
}

function Write-Warning { 
    Write-Host "  ⚠️  $($args -join ' ')" -ForegroundColor Yellow 
}

function Write-Error { 
    Write-Host "  ❌ $($args -join ' ')" -ForegroundColor Red 
}

function Test-CommandExists {
    param($Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-WithChocolatey {
    param(
        [string]$Package,
        [string]$DisplayName,
        [string]$Version = ""
    )
    
    Write-Step "Installing $DisplayName..."
    
    if ($WhatIf) {
        Write-Warning "Would install: choco install $Package $Version -y"
        return
    }
    
    try {
        if ($Version) {
            choco install $Package --version=$Version -y --no-progress | Out-Host
        } else {
            choco install $Package -y --no-progress | Out-Host
        }
        Write-Success "$DisplayName installed successfully"
    } catch {
        Write-Error "Failed to install $DisplayName: $_"
        return $false
    }
    return $true
}

function Install-FromUrl {
    param(
        [string]$Url,
        [string]$DisplayName,
        [string]$FileName
    )
    
    Write-Step "Downloading $DisplayName..."
    
    if ($WhatIf) {
        Write-Warning "Would download from: $Url"
        return
    }
    
    $tempPath = Join-Path $env:TEMP $FileName
    
    try {
        Invoke-WebRequest -Uri $Url -OutFile $tempPath -UseBasicParsing
        Write-Success "Downloaded $DisplayName"
        
        # Execute installer
        if ($FileName -match '\.msi$') {
            Start-Process msiexec.exe -ArgumentList "/i", $tempPath, "/quiet", "/norestart" -Wait
        } elseif ($FileName -match '\.exe$') {
            Start-Process $tempPath -ArgumentList "/silent" -Wait
        }
        
        Write-Success "$DisplayName installed"
        Remove-Item $tempPath -Force
    } catch {
        Write-Error "Failed to install $DisplayName: $_"
        return $false
    }
    return $true
}

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "  Terraform Lab Tools Installer" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Check and install Chocolatey first
if (-not (Test-CommandExists "choco")) {
    Write-Step "Installing Chocolatey package manager..."
    
    if ($WhatIf) {
        Write-Warning "Would install Chocolatey"
    } else {
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            
            # Refresh environment
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            Write-Success "Chocolatey installed successfully"
        } catch {
            Write-Error "Failed to install Chocolatey: $_"
            Write-Host "`nPlease install Chocolatey manually from: https://chocolatey.org/install" -ForegroundColor Yellow
            exit 1
        }
    }
}

# Core Tools
if ($Core) {
    Write-Host "`n🔧 INSTALLING CORE TOOLS" -ForegroundColor White
    Write-Host "------------------------" -ForegroundColor Gray
    
    # Terraform
    if (-not (Test-CommandExists "terraform")) {
        Install-WithChocolatey -Package "terraform" -DisplayName "Terraform"
    } else {
        Write-Success "Terraform already installed"
    }
    
    # Git
    if (-not (Test-CommandExists "git")) {
        Install-WithChocolatey -Package "git" -DisplayName "Git"
    } else {
        Write-Success "Git already installed"
    }
    
    # VS Code
    if (-not (Test-CommandExists "code")) {
        $installVSCode = Read-Host "`nInstall VS Code? (recommended) [Y/n]"
        if ($installVSCode -ne 'n') {
            Install-WithChocolatey -Package "vscode" -DisplayName "Visual Studio Code"
            
            # Install extensions
            if (-not $WhatIf) {
                Write-Step "Installing VS Code extensions..."
                code --install-extension hashicorp.terraform 2>$null
                code --install-extension ms-vscode-remote.remote-containers 2>$null
                code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools 2>$null
                code --install-extension ms-azuretools.vscode-docker 2>$null
                Write-Success "VS Code extensions installed"
            }
        }
    } else {
        Write-Success "VS Code already installed"
    }
    
    # Windows Terminal
    if (-not (Get-AppxPackage -Name Microsoft.WindowsTerminal -ErrorAction SilentlyContinue)) {
        $installWT = Read-Host "`nInstall Windows Terminal? (recommended) [Y/n]"
        if ($installWT -ne 'n') {
            Install-WithChocolatey -Package "microsoft-windows-terminal" -DisplayName "Windows Terminal"
        }
    }
}

# Container Tools
if ($Containers) {
    Write-Host "`n🐋 INSTALLING CONTAINER TOOLS" -ForegroundColor White
    Write-Host "-----------------------------" -ForegroundColor Gray
    
    # Check WSL2 first
    $wslInstalled = Get-Command wsl -ErrorAction SilentlyContinue
    if (-not $wslInstalled) {
        Write-Step "Installing WSL2..."
        
        if (-not $WhatIf) {
            wsl --install --no-launch
            Write-Success "WSL2 installed (restart required)"
            Write-Warning "Please restart your computer after installation completes"
        }
    }
    
    # Docker Desktop
    $dockerDesktop = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
        Where-Object { $_.DisplayName -like "*Docker Desktop*" }
    
    if (-not $dockerDesktop) {
        Write-Step "Installing Docker Desktop..."
        
        $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        
        if ($WhatIf) {
            Write-Warning "Would download and install Docker Desktop"
        } else {
            $installerPath = Join-Path $env:TEMP "DockerDesktopInstaller.exe"
            
            try {
                Write-Host "  Downloading Docker Desktop..." -ForegroundColor Gray
                Invoke-WebRequest -Uri $dockerUrl -OutFile $installerPath -UseBasicParsing
                
                Write-Host "  Installing Docker Desktop (this may take several minutes)..." -ForegroundColor Gray
                Start-Process $installerPath -ArgumentList "install", "--quiet", "--accept-license" -Wait
                
                Write-Success "Docker Desktop installed"
                Write-Warning "Please log out and back in for Docker Desktop to work properly"
                
                Remove-Item $installerPath -Force
            } catch {
                Write-Error "Failed to install Docker Desktop: $_"
                Write-Host "  Download manually from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Success "Docker Desktop already installed"
    }
    
    # Docker Compose (standalone)
    if (-not (Test-CommandExists "docker-compose")) {
        Install-WithChocolatey -Package "docker-compose" -DisplayName "Docker Compose"
    }
}

# Kubernetes Tools
if ($Kubernetes) {
    Write-Host "`n☸️  INSTALLING KUBERNETES TOOLS" -ForegroundColor White
    Write-Host "------------------------------" -ForegroundColor Gray
    
    # kubectl
    if (-not (Test-CommandExists "kubectl")) {
        Install-WithChocolatey -Package "kubernetes-cli" -DisplayName "kubectl"
    } else {
        Write-Success "kubectl already installed"
    }
    
    # minikube
    if (-not (Test-CommandExists "minikube")) {
        Install-WithChocolatey -Package "minikube" -DisplayName "Minikube"
    } else {
        Write-Success "Minikube already installed"
    }
    
    # helm
    if (-not (Test-CommandExists "helm")) {
        Install-WithChocolatey -Package "kubernetes-helm" -DisplayName "Helm"
    } else {
        Write-Success "Helm already installed"
    }
    
    # kind (optional)
    $installKind = Read-Host "`nInstall Kind (Kubernetes in Docker)? [y/N]"
    if ($installKind -eq 'y') {
        Install-WithChocolatey -Package "kind" -DisplayName "Kind"
    }
    
    # k9s (optional terminal UI)
    $installK9s = Read-Host "`nInstall k9s (Kubernetes terminal UI)? [y/N]"
    if ($installK9s -eq 'y') {
        Install-WithChocolatey -Package "k9s" -DisplayName "k9s"
    }
    
    # lens (optional GUI)
    $installLens = Read-Host "`nInstall Lens (Kubernetes IDE)? [y/N]"
    if ($installLens -eq 'y') {
        Install-WithChocolatey -Package "lens" -DisplayName "Lens"
    }
}

# Cloud Provider CLIs
if ($Cloud) {
    Write-Host "`n☁️  INSTALLING CLOUD PROVIDER TOOLS" -ForegroundColor White
    Write-Host "----------------------------------" -ForegroundColor Gray
    
    # AWS CLI
    $installAWS = Read-Host "`nInstall AWS CLI? [y/N]"
    if ($installAWS -eq 'y') {
        if (-not (Test-CommandExists "aws")) {
            Install-WithChocolatey -Package "awscli" -DisplayName "AWS CLI"
        } else {
            Write-Success "AWS CLI already installed"
        }
    }
    
    # Azure CLI
    $installAzure = Read-Host "`nInstall Azure CLI? [y/N]"
    if ($installAzure -eq 'y') {
        if (-not (Test-CommandExists "az")) {
            Install-WithChocolatey -Package "azure-cli" -DisplayName "Azure CLI"
        } else {
            Write-Success "Azure CLI already installed"
        }
    }
    
    # Google Cloud SDK
    $installGCP = Read-Host "`nInstall Google Cloud SDK? [y/N]"
    if ($installGCP -eq 'y') {
        if (-not (Test-CommandExists "gcloud")) {
            Install-WithChocolatey -Package "gcloudsdk" -DisplayName "Google Cloud SDK"
        } else {
            Write-Success "Google Cloud SDK already installed"
        }
    }
}

# Configuration Management Tools
if ($ConfigManagement) {
    Write-Host "`n🔧 INSTALLING CONFIGURATION MANAGEMENT TOOLS" -ForegroundColor White
    Write-Host "-------------------------------------------" -ForegroundColor Gray
    
    # Ansible (via WSL2)
    $installAnsible = Read-Host "`nInstall Ansible? (requires WSL2) [y/N]"
    if ($installAnsible -eq 'y') {
        if (Get-Command wsl -ErrorAction SilentlyContinue) {
            Write-Step "Installing Ansible in WSL2..."
            
            if (-not $WhatIf) {
                # Check if Ubuntu is installed
                $ubuntuInstalled = wsl -l -v 2>$null | Select-String "Ubuntu"
                if (-not $ubuntuInstalled) {
                    Write-Host "  Installing Ubuntu in WSL2..." -ForegroundColor Gray
                    wsl --install -d Ubuntu --no-launch
                    Write-Warning "Ubuntu installed. Please complete setup and run this script again."
                } else {
                    # Install Ansible in Ubuntu
                    wsl -d Ubuntu -e bash -c "sudo apt-get update && sudo apt-get install -y ansible"
                    Write-Success "Ansible installed in WSL2"
                    
                    # Create Windows wrapper script
                    $wrapperPath = "C:\Tools\ansible.bat"
                    $wrapperContent = '@echo off
wsl -d Ubuntu ansible %*'
                    New-Item -Path "C:\Tools" -ItemType Directory -Force | Out-Null
                    Set-Content -Path $wrapperPath -Value $wrapperContent
                    
                    # Add to PATH
                    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
                    if ($currentPath -notlike "*C:\Tools*") {
                        [Environment]::SetEnvironmentVariable("Path", "$currentPath;C:\Tools", "User")
                        Write-Success "Added Ansible wrapper to PATH"
                    }
                }
            }
        } else {
            Write-Warning "WSL2 not installed. Install WSL2 first with -Containers flag"
        }
    }
    
    # Packer
    $installPacker = Read-Host "`nInstall Packer? [y/N]"
    if ($installPacker -eq 'y') {
        if (-not (Test-CommandExists "packer")) {
            Install-WithChocolatey -Package "packer" -DisplayName "Packer"
        } else {
            Write-Success "Packer already installed"
        }
    }
    
    # Vault
    $installVault = Read-Host "`nInstall Vault? [y/N]"
    if ($installVault -eq 'y') {
        if (-not (Test-CommandExists "vault")) {
            Install-WithChocolatey -Package "vault" -DisplayName "Vault"
        } else {
            Write-Success "Vault already installed"
        }
    }
    
    # Consul
    $installConsul = Read-Host "`nInstall Consul? [y/N]"
    if ($installConsul -eq 'y') {
        if (-not (Test-CommandExists "consul")) {
            Install-WithChocolatey -Package "consul" -DisplayName "Consul"
        } else {
            Write-Success "Consul already installed"
        }
    }
}

# Refresh environment variables
Write-Host "`n🔄 Refreshing environment variables..." -ForegroundColor Cyan
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Run environment check
Write-Host "`n📋 Running environment check..." -ForegroundColor Cyan
& "$PSScriptRoot\Check-Environment.ps1"

Write-Host "`n✨ Installation complete!" -ForegroundColor Green
Write-Host "   Some tools may require a restart or re-login to work properly." -ForegroundColor Yellow
Write-Host "   Run .\Initialize-LabServices.ps1 to start services." -ForegroundColor Cyan