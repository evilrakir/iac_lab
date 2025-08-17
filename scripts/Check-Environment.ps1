# Note: Some checks work better with admin rights but not required
<#
.SYNOPSIS
    Comprehensive environment checker for Terraform Learning Lab
.DESCRIPTION
    Checks for all required and optional tools, their versions, and configurations
.EXAMPLE
    .\Check-Environment.ps1
.EXAMPLE
    .\Check-Environment.ps1 -Detailed
#>
[CmdletBinding()]
param(
    [switch]$Detailed,
    [switch]$JsonOutput
)

$ErrorActionPreference = "SilentlyContinue"
$VerbosePreference = if ($Detailed) { "Continue" } else { "SilentlyContinue" }

# Color functions for output
function Write-Success { Write-Host "✅ $($args -join ' ')" -ForegroundColor Green }
function Write-Warning { Write-Host "⚠️  $($args -join ' ')" -ForegroundColor Yellow }
function Write-Error { Write-Host "❌ $($args -join ' ')" -ForegroundColor Red }
function Write-Info { Write-Host "ℹ️  $($args -join ' ')" -ForegroundColor Cyan }
function Write-Optional { Write-Host "📌 $($args -join ' ')" -ForegroundColor Gray }

$report = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Core = @{}
    CloudProviders = @{}
    Containers = @{}
    Kubernetes = @{}
    ConfigManagement = @{}
    Monitoring = @{}
    Legacy = @{}
    Windows = @{}
    Recommendations = @()
}

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "  Terraform Lab Environment Check" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "=====================================`n" -ForegroundColor Cyan

# Core Tools Check
Write-Host "`n🔧 CORE TOOLS (Required)" -ForegroundColor White
Write-Host "------------------------" -ForegroundColor Gray

# Terraform
$terraform = Get-Command terraform -ErrorAction SilentlyContinue
if ($terraform) {
    $version = terraform version -json 2>$null | ConvertFrom-Json
    $tfVersion = $version.terraform_version
    Write-Success "Terraform: $tfVersion"
    $report.Core.Terraform = @{ Installed = $true; Version = $tfVersion }
    
    # Check for .terraform directories
    $tfDirs = Get-ChildItem -Path .. -Recurse -Directory -Filter ".terraform" 2>$null
    if ($tfDirs) {
        Write-Warning "  Found $($tfDirs.Count) initialized Terraform directories"
    }
} else {
    Write-Error "Terraform: Not installed"
    $report.Core.Terraform = @{ Installed = $false }
    $report.Recommendations += "Install Terraform: choco install terraform"
}

# Git
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    $gitVersion = git --version
    Write-Success "Git: $gitVersion"
    $report.Core.Git = @{ Installed = $true; Version = $gitVersion }
} else {
    Write-Error "Git: Not installed"
    $report.Core.Git = @{ Installed = $false }
    $report.Recommendations += "Install Git: choco install git"
}

# VS Code (Optional but recommended)
$vscode = Get-Command code -ErrorAction SilentlyContinue
if ($vscode) {
    Write-Success "VS Code: Installed"
    $report.Core.VSCode = @{ Installed = $true }
    
    # Check for Terraform extension
    $extensions = code --list-extensions 2>$null
    if ($extensions -contains "hashicorp.terraform") {
        Write-Success "  Terraform Extension: Installed"
    } else {
        Write-Warning "  Terraform Extension: Not installed"
        $report.Recommendations += "Install VS Code Terraform extension: code --install-extension hashicorp.terraform"
    }
} else {
    Write-Warning "VS Code: Not installed (optional but recommended)"
    $report.Core.VSCode = @{ Installed = $false }
}

# Container Tools
Write-Host "`n🐋 CONTAINER TOOLS" -ForegroundColor White
Write-Host "------------------" -ForegroundColor Gray

# Docker Desktop
$dockerDesktop = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
    Where-Object { $_.DisplayName -like "*Docker Desktop*" }
if ($dockerDesktop) {
    Write-Success "Docker Desktop: $($dockerDesktop.DisplayVersion)"
    $report.Containers.DockerDesktop = @{ Installed = $true; Version = $dockerDesktop.DisplayVersion }
    
    # Check if Docker daemon is running
    $dockerRunning = docker version 2>$null
    if ($dockerRunning) {
        Write-Success "  Docker Daemon: Running"
        $dockerVersion = docker version --format '{{.Client.Version}}' 2>$null
        Write-Info "  Docker Client: $dockerVersion"
        $report.Containers.DockerDaemon = @{ Running = $true; Version = $dockerVersion }
    } else {
        Write-Warning "  Docker Daemon: Not running"
        $report.Containers.DockerDaemon = @{ Running = $false }
        $report.Recommendations += "Start Docker Desktop from Start Menu"
    }
    
    # Check WSL2
    $wslStatus = wsl -l -v 2>$null
    if ($wslStatus -match "docker-desktop") {
        Write-Success "  WSL2 Backend: Configured"
        $report.Containers.WSL2 = @{ Configured = $true }
    }
} else {
    Write-Error "Docker Desktop: Not installed"
    $report.Containers.DockerDesktop = @{ Installed = $false }
    $report.Recommendations += "Install Docker Desktop: https://www.docker.com/products/docker-desktop"
}

# Podman (Alternative to Docker)
$podman = Get-Command podman -ErrorAction SilentlyContinue
if ($podman) {
    $podmanVersion = podman --version
    Write-Success "Podman: $podmanVersion (Docker alternative)"
    $report.Containers.Podman = @{ Installed = $true; Version = $podmanVersion }
} else {
    Write-Optional "Podman: Not installed (optional Docker alternative)"
}

# Kubernetes Tools
Write-Host "`n☸️  KUBERNETES TOOLS" -ForegroundColor White
Write-Host "-------------------" -ForegroundColor Gray

# kubectl
$kubectl = Get-Command kubectl -ErrorAction SilentlyContinue
if ($kubectl) {
    $kubectlVersion = kubectl version --client --short 2>$null
    Write-Success "kubectl: $kubectlVersion"
    $report.Kubernetes.kubectl = @{ Installed = $true; Version = $kubectlVersion }
    
    # Check current context
    $currentContext = kubectl config current-context 2>$null
    if ($currentContext) {
        Write-Info "  Current context: $currentContext"
    }
} else {
    Write-Error "kubectl: Not installed"
    $report.Kubernetes.kubectl = @{ Installed = $false }
    $report.Recommendations += "Install kubectl: choco install kubernetes-cli"
}

# Minikube
$minikube = Get-Command minikube -ErrorAction SilentlyContinue
if ($minikube) {
    $minikubeVersion = minikube version --short 2>$null
    Write-Success "Minikube: $minikubeVersion"
    $report.Kubernetes.Minikube = @{ Installed = $true; Version = $minikubeVersion }
    
    # Check status
    $minikubeStatus = minikube status 2>$null
    if ($minikubeStatus -match "Running") {
        Write-Success "  Minikube cluster: Running"
    } else {
        Write-Warning "  Minikube cluster: Not running"
        Write-Info "  Start with: minikube start --driver=hyperv"
    }
} else {
    Write-Error "Minikube: Not installed"
    $report.Kubernetes.Minikube = @{ Installed = $false }
    $report.Recommendations += "Install Minikube: choco install minikube"
}

# Helm
$helm = Get-Command helm -ErrorAction SilentlyContinue
if ($helm) {
    $helmVersion = helm version --short 2>$null
    Write-Success "Helm: $helmVersion"
    $report.Kubernetes.Helm = @{ Installed = $true; Version = $helmVersion }
} else {
    Write-Error "Helm: Not installed"
    $report.Kubernetes.Helm = @{ Installed = $false }
    $report.Recommendations += "Install Helm: choco install kubernetes-helm"
}

# Kind (Kubernetes in Docker)
$kind = Get-Command kind -ErrorAction SilentlyContinue
if ($kind) {
    $kindVersion = kind version
    Write-Success "Kind: $kindVersion"
    $report.Kubernetes.Kind = @{ Installed = $true; Version = $kindVersion }
} else {
    Write-Warning "Kind: Not installed (alternative to Minikube)"
    $report.Recommendations += "Install Kind (optional): choco install kind"
}

# Cloud Provider CLIs
Write-Host "`n☁️  CLOUD PROVIDER TOOLS" -ForegroundColor White
Write-Host "-----------------------" -ForegroundColor Gray

# AWS CLI
$aws = Get-Command aws -ErrorAction SilentlyContinue
if ($aws) {
    $awsVersion = aws --version 2>$null
    Write-Success "AWS CLI: $awsVersion"
    $report.CloudProviders.AWS = @{ Installed = $true; Version = $awsVersion }
    
    # Check credentials
    $awsCreds = aws sts get-caller-identity 2>$null
    if ($awsCreds) {
        Write-Success "  AWS Credentials: Configured"
    } else {
        Write-Warning "  AWS Credentials: Not configured"
        Write-Info "  Configure with: aws configure"
    }
} else {
    Write-Warning "AWS CLI: Not installed"
    $report.CloudProviders.AWS = @{ Installed = $false }
}

# Azure CLI
$az = Get-Command az -ErrorAction SilentlyContinue
if ($az) {
    $azVersion = az version --output json 2>$null | ConvertFrom-Json
    Write-Success "Azure CLI: $($azVersion.'azure-cli')"
    $report.CloudProviders.Azure = @{ Installed = $true; Version = $azVersion.'azure-cli' }
    
    # Check login status
    $azAccount = az account show 2>$null
    if ($azAccount) {
        Write-Success "  Azure: Logged in"
    } else {
        Write-Warning "  Azure: Not logged in"
        Write-Info "  Login with: az login"
    }
} else {
    Write-Warning "Azure CLI: Not installed"
    $report.CloudProviders.Azure = @{ Installed = $false }
}

# Google Cloud SDK
$gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
if ($gcloud) {
    $gcloudVersion = gcloud version --format=json 2>$null | ConvertFrom-Json
    Write-Success "Google Cloud SDK: $($gcloudVersion.'Google Cloud SDK')"
    $report.CloudProviders.GCP = @{ Installed = $true; Version = $gcloudVersion.'Google Cloud SDK' }
} else {
    Write-Warning "Google Cloud SDK: Not installed"
    $report.CloudProviders.GCP = @{ Installed = $false }
}

# Configuration Management
Write-Host "`n🔧 CONFIGURATION MANAGEMENT" -ForegroundColor White
Write-Host "---------------------------" -ForegroundColor Gray

# Ansible
$ansible = Get-Command ansible -ErrorAction SilentlyContinue
if ($ansible) {
    $ansibleVersion = ansible --version | Select-Object -First 1
    Write-Success "Ansible: $ansibleVersion"
    $report.ConfigManagement.Ansible = @{ Installed = $true; Version = $ansibleVersion }
} else {
    Write-Warning "Ansible: Not installed"
    $report.ConfigManagement.Ansible = @{ Installed = $false }
    Write-Info "  Install via WSL2 or use Ansible for Windows"
    $report.Recommendations += "Install Ansible via WSL2: wsl -e sudo apt-get install ansible"
}

# Packer
$packer = Get-Command packer -ErrorAction SilentlyContinue
if ($packer) {
    $packerVersion = packer version
    Write-Success "Packer: $packerVersion"
    $report.ConfigManagement.Packer = @{ Installed = $true; Version = $packerVersion }
} else {
    Write-Warning "Packer: Not installed (optional)"
    $report.ConfigManagement.Packer = @{ Installed = $false }
}

# Vault
$vault = Get-Command vault -ErrorAction SilentlyContinue
if ($vault) {
    $vaultVersion = vault version
    Write-Success "Vault: $vaultVersion"
    $report.ConfigManagement.Vault = @{ Installed = $true; Version = $vaultVersion }
} else {
    Write-Warning "Vault: Not installed (optional)"
    $report.ConfigManagement.Vault = @{ Installed = $false }
}

# Monitoring Tools
Write-Host "`n📊 MONITORING TOOLS" -ForegroundColor White
Write-Host "-------------------" -ForegroundColor Gray

# Check for Prometheus/Grafana (usually containerized)
if ($dockerRunning) {
    $promContainer = docker ps --filter "ancestor=prom/prometheus" --format "table {{.Names}}" 2>$null
    if ($promContainer) {
        Write-Success "Prometheus: Running in container"
    } else {
        Write-Info "Prometheus: Not running (deploy with Terraform)"
    }
    
    $grafanaContainer = docker ps --filter "ancestor=grafana/grafana" --format "table {{.Names}}" 2>$null
    if ($grafanaContainer) {
        Write-Success "Grafana: Running in container"
    } else {
        Write-Info "Grafana: Not running (deploy with Terraform)"
    }
}

# Windows Specific
Write-Host "`n🪟 WINDOWS ENVIRONMENT" -ForegroundColor White
Write-Host "----------------------" -ForegroundColor Gray

# PowerShell Version
$psVersion = $PSVersionTable.PSVersion.ToString()
Write-Success "PowerShell: $psVersion"
$report.Windows.PowerShell = @{ Version = $psVersion }

# Check Hyper-V
$hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All 2>$null
if ($hyperV -and $hyperV.State -eq "Enabled") {
    Write-Success "Hyper-V: Enabled"
    $report.Windows.HyperV = @{ Enabled = $true }
    
    # Check if user is in Hyper-V Administrators group
    $isHyperVAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Hyper-V Administrators")
    if (-not $isHyperVAdmin) {
        Write-Warning "  User not in Hyper-V Administrators group"
        $report.Recommendations += "Add user to Hyper-V Administrators group for VM management"
    }
} else {
    Write-Warning "Hyper-V: Not enabled"
    $report.Windows.HyperV = @{ Enabled = $false }
}

# Check WSL2
$wsl = Get-Command wsl -ErrorAction SilentlyContinue
if ($wsl) {
    $wslVersion = wsl --version 2>$null | Select-Object -First 1
    Write-Success "WSL2: $wslVersion"
    $report.Windows.WSL2 = @{ Installed = $true }
    
    # List distributions
    $distributions = wsl -l -v 2>$null | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
    if ($distributions) {
        Write-Info "  Distributions:"
        $distributions | ForEach-Object { Write-Info "    $_" }
    }
} else {
    Write-Error "WSL2: Not installed"
    $report.Windows.WSL2 = @{ Installed = $false }
    $report.Recommendations += "Enable WSL2: wsl --install"
}

# Check Windows Terminal
$winTerminal = Get-AppxPackage -Name Microsoft.WindowsTerminal -ErrorAction SilentlyContinue
if ($winTerminal) {
    Write-Success "Windows Terminal: $($winTerminal.Version)"
    $report.Windows.Terminal = @{ Installed = $true; Version = $winTerminal.Version }
} else {
    Write-Warning "Windows Terminal: Not installed (recommended)"
}

# Check Chocolatey
$choco = Get-Command choco -ErrorAction SilentlyContinue
if ($choco) {
    $chocoVersion = choco --version 2>$null
    Write-Success "Chocolatey: $chocoVersion"
    $report.Windows.Chocolatey = @{ Installed = $true; Version = $chocoVersion }
} else {
    Write-Error "Chocolatey: Not installed"
    $report.Windows.Chocolatey = @{ Installed = $false }
    Write-Info "  Install from: https://chocolatey.org/install"
}

# Legacy/Optional Tools
Write-Host "`n📦 LEGACY/OPTIONAL TOOLS" -ForegroundColor White
Write-Host "------------------------" -ForegroundColor Gray

# Vagrant
$vagrant = Get-Command vagrant -ErrorAction SilentlyContinue
if ($vagrant) {
    $vagrantVersion = vagrant version 2>$null | Select-Object -First 1
    Write-Optional "[LEGACY] Vagrant: $vagrantVersion"
    $report.Legacy.Vagrant = @{ Installed = $true; Version = $vagrantVersion }
} else {
    Write-Optional "[LEGACY] Vagrant: Not installed (superseded by containers)"
}

# Chef/Puppet (Legacy CM tools)
$chef = Get-Command chef -ErrorAction SilentlyContinue
if ($chef) {
    Write-Optional "[LEGACY] Chef: Installed"
    $report.Legacy.Chef = @{ Installed = $true }
} else {
    Write-Optional "[LEGACY] Chef: Not installed (consider Ansible instead)"
}

# Summary and Recommendations
Write-Host "`n📋 SUMMARY" -ForegroundColor White
Write-Host "----------" -ForegroundColor Gray

$coreReady = $report.Core.Terraform.Installed -and $report.Core.Git.Installed
$containerReady = $report.Containers.DockerDesktop.Installed -or $report.Containers.Podman.Installed
$k8sReady = $report.Kubernetes.kubectl.Installed

if ($coreReady) {
    Write-Success "Core tools ready for Terraform development"
} else {
    Write-Error "Missing core tools - install Terraform and Git"
}

if ($containerReady) {
    Write-Success "Container environment ready"
} else {
    Write-Warning "Container tools not ready - install Docker Desktop"
}

if ($k8sReady) {
    Write-Success "Kubernetes tools available"
} else {
    Write-Warning "Kubernetes tools missing - install kubectl and minikube/kind"
}

if ($report.Recommendations.Count -gt 0) {
    Write-Host "`n🔧 RECOMMENDATIONS" -ForegroundColor White
    Write-Host "-----------------" -ForegroundColor Gray
    $report.Recommendations | Select-Object -Unique | ForEach-Object {
        Write-Info "• $_"
    }
}

# Export to JSON if requested
if ($JsonOutput) {
    $jsonPath = Join-Path $PSScriptRoot "environment-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-Host "`n📄 Report saved to: $jsonPath" -ForegroundColor Green
}

Write-Host "`n✨ Environment check complete!`n" -ForegroundColor Green

# Return status code
if (-not $coreReady) {
    exit 1
}
exit 0