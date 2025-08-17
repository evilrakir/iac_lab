#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Initialize and start services for Terraform Lab
.DESCRIPTION
    Starts Docker, Minikube, and other services needed for the lab exercises
.PARAMETER Docker
    Start Docker Desktop
.PARAMETER Kubernetes
    Start Kubernetes cluster (Minikube or Docker Desktop K8s)
.PARAMETER Monitoring
    Deploy Prometheus and Grafana stack
.PARAMETER All
    Start all services
.EXAMPLE
    .\Initialize-LabServices.ps1 -Docker
.EXAMPLE
    .\Initialize-LabServices.ps1 -All
#>
[CmdletBinding()]
param(
    [switch]$Docker,
    [switch]$Kubernetes,
    [switch]$Monitoring,
    [switch]$All,
    [switch]$Stop,
    [switch]$Status
)

$ErrorActionPreference = "Continue"

if ($All) {
    $Docker = $Kubernetes = $Monitoring = $true
}

# If no specific service selected and not status/stop, default to Docker
if (-not ($Docker -or $Kubernetes -or $Monitoring -or $Status -or $Stop)) {
    $Docker = $true
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

function Write-Info { 
    Write-Host "  ℹ️  $($args -join ' ')" -ForegroundColor Cyan 
}

function Test-CommandExists {
    param($Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Start-DockerDesktop {
    Write-Step "Starting Docker Desktop..."
    
    # Check if Docker Desktop is installed
    $dockerDesktop = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
        Where-Object { $_.DisplayName -like "*Docker Desktop*" }
    
    if (-not $dockerDesktop) {
        Write-Error "Docker Desktop not installed"
        Write-Info "Install with: .\Install-LabTools.ps1 -Containers"
        return $false
    }
    
    # Check if Docker daemon is already running
    $dockerRunning = docker version 2>$null
    if ($dockerRunning) {
        Write-Success "Docker is already running"
        
        # Show Docker info
        $dockerInfo = docker info --format '{{json .}}' 2>$null | ConvertFrom-Json
        Write-Info "Docker version: $($dockerInfo.ServerVersion)"
        Write-Info "Containers: $($dockerInfo.Containers) (Running: $($dockerInfo.ContainersRunning))"
        Write-Info "Images: $($dockerInfo.Images)"
        
        return $true
    }
    
    # Start Docker Desktop
    Write-Info "Starting Docker Desktop (this may take a minute)..."
    
    # Find Docker Desktop executable
    $dockerPath = @(
        "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe",
        "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe",
        "${env:LocalAppData}\Docker\Docker Desktop.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    
    if ($dockerPath) {
        Start-Process $dockerPath
        
        # Wait for Docker to be ready
        Write-Info "Waiting for Docker daemon to start..."
        $maxWait = 60
        $waited = 0
        
        while ($waited -lt $maxWait) {
            Start-Sleep -Seconds 2
            $waited += 2
            
            $dockerReady = docker version 2>$null
            if ($dockerReady) {
                Write-Success "Docker Desktop started successfully"
                return $true
            }
            
            Write-Host "." -NoNewline
        }
        
        Write-Error "Docker Desktop failed to start within $maxWait seconds"
        Write-Info "Please start Docker Desktop manually from the Start Menu"
        return $false
    } else {
        Write-Error "Could not find Docker Desktop executable"
        return $false
    }
}

function Stop-DockerDesktop {
    Write-Step "Stopping Docker Desktop..."
    
    $dockerRunning = docker version 2>$null
    if (-not $dockerRunning) {
        Write-Info "Docker is not running"
        return
    }
    
    # Stop all running containers
    $runningContainers = docker ps -q 2>$null
    if ($runningContainers) {
        Write-Info "Stopping running containers..."
        docker stop $runningContainers 2>$null
    }
    
    # Quit Docker Desktop
    Write-Info "Stopping Docker Desktop..."
    
    # Try graceful shutdown first
    $dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
    if ($dockerProcess) {
        $dockerProcess.CloseMainWindow() | Out-Null
        Start-Sleep -Seconds 5
    }
    
    # Force stop if still running
    Get-Process "Docker Desktop", "com.docker.*" -ErrorAction SilentlyContinue | Stop-Process -Force
    
    Write-Success "Docker Desktop stopped"
}

function Start-MinikubeCluster {
    Write-Step "Starting Minikube cluster..."
    
    if (-not (Test-CommandExists "minikube")) {
        Write-Error "Minikube not installed"
        Write-Info "Install with: .\Install-LabTools.ps1 -Kubernetes"
        return $false
    }
    
    # Check current status
    $status = minikube status --format='{{.Host}}' 2>$null
    
    if ($status -eq "Running") {
        Write-Success "Minikube is already running"
        
        # Show cluster info
        $clusterInfo = kubectl cluster-info 2>$null
        if ($clusterInfo) {
            Write-Info "Cluster info:"
            $clusterInfo | ForEach-Object { Write-Info "  $_" }
        }
        
        return $true
    }
    
    # Determine driver
    $driver = "hyperv"  # Default for Windows
    
    # Check if Docker is available
    $dockerAvailable = docker version 2>$null
    if ($dockerAvailable) {
        $useDocker = Read-Host "Docker is available. Use Docker driver instead of Hyper-V? [Y/n]"
        if ($useDocker -ne 'n') {
            $driver = "docker"
        }
    }
    
    # Check Hyper-V if using hyperv driver
    if ($driver -eq "hyperv") {
        $hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All 2>$null
        if (-not $hyperV -or $hyperV.State -ne "Enabled") {
            Write-Error "Hyper-V is not enabled"
            Write-Info "Enable with: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All"
            return $false
        }
        
        # Check if user is in Hyper-V Administrators group
        $isHyperVAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Hyper-V Administrators")
        if (-not $isHyperVAdmin) {
            Write-Warning "Current user is not in Hyper-V Administrators group"
            Write-Info "Add user to group: Add-LocalGroupMember -Group 'Hyper-V Administrators' -Member $env:USERNAME"
            Write-Info "Then log out and back in"
        }
    }
    
    # Start Minikube
    Write-Info "Starting Minikube with $driver driver..."
    Write-Info "This may take several minutes on first run..."
    
    $cpus = Read-Host "Number of CPUs for cluster (default: 2)"
    if (-not $cpus) { $cpus = "2" }
    
    $memory = Read-Host "Memory in MB (default: 4096)"
    if (-not $memory) { $memory = "4096" }
    
    $startCmd = "minikube start --driver=$driver --cpus=$cpus --memory=$memory"
    
    if ($driver -eq "hyperv") {
        # For Hyper-V, we might need to specify virtual switch
        $switches = Get-VMSwitch | Where-Object { $_.SwitchType -eq "External" }
        if ($switches) {
            Write-Info "Available virtual switches:"
            $switches | ForEach-Object { Write-Info "  - $($_.Name)" }
            $switchName = Read-Host "Enter virtual switch name (or press Enter for default)"
            if ($switchName) {
                $startCmd += " --hyperv-virtual-switch='$switchName'"
            }
        }
    }
    
    Write-Info "Executing: $startCmd"
    Invoke-Expression $startCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Minikube started successfully"
        
        # Enable useful addons
        Write-Info "Enabling addons..."
        minikube addons enable dashboard 2>$null
        minikube addons enable metrics-server 2>$null
        minikube addons enable ingress 2>$null
        
        # Show how to access dashboard
        Write-Info "Access Kubernetes dashboard with: minikube dashboard"
        
        return $true
    } else {
        Write-Error "Failed to start Minikube"
        Write-Info "Check logs with: minikube logs"
        return $false
    }
}

function Stop-MinikubeCluster {
    Write-Step "Stopping Minikube cluster..."
    
    if (-not (Test-CommandExists "minikube")) {
        Write-Info "Minikube not installed"
        return
    }
    
    $status = minikube status --format='{{.Host}}' 2>$null
    if ($status -ne "Running") {
        Write-Info "Minikube is not running"
        return
    }
    
    minikube stop
    Write-Success "Minikube stopped"
}

function Start-DockerKubernetes {
    Write-Step "Starting Docker Desktop Kubernetes..."
    
    # First ensure Docker is running
    $dockerRunning = docker version 2>$null
    if (-not $dockerRunning) {
        Write-Info "Docker Desktop not running, starting it first..."
        if (-not (Start-DockerDesktop)) {
            return $false
        }
    }
    
    # Check if Kubernetes is enabled in Docker Desktop
    $k8sEnabled = kubectl config get-contexts 2>$null | Select-String "docker-desktop"
    
    if (-not $k8sEnabled) {
        Write-Warning "Kubernetes is not enabled in Docker Desktop"
        Write-Info "To enable:"
        Write-Info "  1. Right-click Docker Desktop tray icon"
        Write-Info "  2. Go to Settings > Kubernetes"
        Write-Info "  3. Check 'Enable Kubernetes'"
        Write-Info "  4. Click 'Apply & Restart'"
        return $false
    }
    
    # Switch to docker-desktop context
    kubectl config use-context docker-desktop 2>$null
    
    # Check if nodes are ready
    $nodes = kubectl get nodes 2>$null
    if ($nodes) {
        Write-Success "Docker Desktop Kubernetes is running"
        Write-Info "Nodes:"
        $nodes | ForEach-Object { Write-Info "  $_" }
        return $true
    } else {
        Write-Error "Kubernetes is enabled but not responding"
        return $false
    }
}

function Deploy-MonitoringStack {
    Write-Step "Deploying Monitoring Stack (Prometheus + Grafana)..."
    
    # Check if kubectl is available
    if (-not (Test-CommandExists "kubectl")) {
        Write-Error "kubectl not installed"
        return $false
    }
    
    # Check if cluster is running
    $nodes = kubectl get nodes 2>$null
    if (-not $nodes) {
        Write-Error "No Kubernetes cluster running"
        Write-Info "Start with: .\Initialize-LabServices.ps1 -Kubernetes"
        return $false
    }
    
    # Create monitoring namespace
    Write-Info "Creating monitoring namespace..."
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f - 2>$null
    
    # Check if Helm is installed
    if (Test-CommandExists "helm") {
        Write-Info "Installing Prometheus and Grafana via Helm..."
        
        # Add Prometheus community repo
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>$null
        helm repo add grafana https://grafana.github.io/helm-charts 2>$null
        helm repo update 2>$null
        
        # Install Prometheus
        Write-Info "Installing Prometheus..."
        helm upgrade --install prometheus prometheus-community/prometheus `
            --namespace monitoring `
            --set server.persistentVolume.enabled=false `
            --set alertmanager.persistentVolume.enabled=false 2>$null
        
        # Install Grafana
        Write-Info "Installing Grafana..."
        helm upgrade --install grafana grafana/grafana `
            --namespace monitoring `
            --set persistence.enabled=false `
            --set adminPassword=admin 2>$null
        
        Write-Success "Monitoring stack deployed"
        
        # Show access information
        Write-Info "Access Prometheus:"
        Write-Info "  kubectl port-forward -n monitoring svc/prometheus-server 9090:80"
        Write-Info "  Then browse to: http://localhost:9090"
        
        Write-Info "Access Grafana:"
        Write-Info "  kubectl port-forward -n monitoring svc/grafana 3000:80"
        Write-Info "  Then browse to: http://localhost:3000"
        Write-Info "  Username: admin"
        Write-Info "  Password: admin"
        
    } else {
        Write-Warning "Helm not installed, using kubectl manifests instead..."
        
        # Create basic Prometheus and Grafana deployments
        $promManifest = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
      volumes:
      - name: config
        configMap:
          name: prometheus-config
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
"@
        
        $grafanaManifest = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: admin
---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
"@
        
        # Apply manifests
        $promManifest | kubectl apply -f - 2>$null
        $grafanaManifest | kubectl apply -f - 2>$null
        
        Write-Success "Basic monitoring stack deployed"
    }
    
    return $true
}

function Get-ServiceStatus {
    Write-Host "`n=====================================" -ForegroundColor Cyan
    Write-Host "  Service Status Report" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    
    # Docker status
    Write-Host "`n🐋 Docker Desktop" -ForegroundColor White
    $dockerRunning = docker version 2>$null
    if ($dockerRunning) {
        Write-Success "Running"
        $containers = docker ps --format "table {{.Names}}\t{{.Status}}" 2>$null
        if ($containers) {
            Write-Info "Active containers:"
            $containers | ForEach-Object { Write-Info "  $_" }
        }
    } else {
        Write-Warning "Not running"
    }
    
    # Kubernetes status
    Write-Host "`n☸️  Kubernetes" -ForegroundColor White
    
    # Check Minikube
    if (Test-CommandExists "minikube") {
        $minikubeStatus = minikube status --format='{{.Host}}' 2>$null
        if ($minikubeStatus -eq "Running") {
            Write-Success "Minikube: Running"
            $context = kubectl config current-context 2>$null
            Write-Info "Current context: $context"
        } else {
            Write-Warning "Minikube: Not running"
        }
    }
    
    # Check Docker Desktop K8s
    $dockerK8s = kubectl config get-contexts 2>$null | Select-String "docker-desktop.*\*"
    if ($dockerK8s) {
        Write-Success "Docker Desktop Kubernetes: Active"
    }
    
    # Check for monitoring stack
    if (Test-CommandExists "kubectl") {
        $monitoring = kubectl get pods -n monitoring 2>$null
        if ($monitoring) {
            Write-Host "`n📊 Monitoring Stack" -ForegroundColor White
            Write-Success "Deployed in 'monitoring' namespace"
            $monitoring | ForEach-Object { Write-Info "  $_" }
        }
    }
    
    # WSL status
    Write-Host "`n🐧 WSL2" -ForegroundColor White
    $wslDistros = wsl -l -v 2>$null | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
    if ($wslDistros) {
        Write-Success "Active distributions:"
        $wslDistros | ForEach-Object { Write-Info "  $_" }
    } else {
        Write-Warning "No WSL distributions running"
    }
}

# Main execution
Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "  Terraform Lab Service Manager" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

if ($Status) {
    Get-ServiceStatus
    exit 0
}

if ($Stop) {
    Write-Step "Stopping services..."
    
    if ($Docker -or $All) {
        Stop-DockerDesktop
    }
    
    if ($Kubernetes -or $All) {
        Stop-MinikubeCluster
    }
    
    Write-Success "Services stopped"
    exit 0
}

# Start services
if ($Docker) {
    Start-DockerDesktop
}

if ($Kubernetes) {
    Write-Step "Select Kubernetes environment:"
    Write-Host "  1. Minikube (lightweight, separate from Docker)" -ForegroundColor Gray
    Write-Host "  2. Docker Desktop Kubernetes (integrated with Docker)" -ForegroundColor Gray
    Write-Host "  3. Both" -ForegroundColor Gray
    
    $choice = Read-Host "Enter choice (1-3)"
    
    switch ($choice) {
        "1" { Start-MinikubeCluster }
        "2" { Start-DockerKubernetes }
        "3" { 
            Start-MinikubeCluster
            Start-DockerKubernetes
        }
        default { 
            Write-Warning "Invalid choice, defaulting to Minikube"
            Start-MinikubeCluster
        }
    }
}

if ($Monitoring) {
    Deploy-MonitoringStack
}

# Show final status
Get-ServiceStatus

Write-Host "`n✨ Service initialization complete!" -ForegroundColor Green
Write-Host "   Run '.\Initialize-LabServices.ps1 -Status' to check service status" -ForegroundColor Cyan
Write-Host "   Run '.\Initialize-LabServices.ps1 -Stop' to stop all services" -ForegroundColor Cyan