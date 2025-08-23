#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive guide for OpenStack Basic VM Deployment
.DESCRIPTION
    Walks through creating a virtual machine with security groups and SSH access
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
║   OPENSTACK BASIC VM DEPLOYMENT - INTERACTIVE GUIDE             ║
║   Exercise 2: Creating Your First Virtual Machine               ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`nThis guide will help you deploy a virtual machine in OpenStack with security groups and SSH access."

# Check if we're in the right directory
if (-not (Test-Path "main.tf")) {
    Write-Warning "main.tf not found. Make sure you're in the 03-openstack/02-basic-vm directory"
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne 'y') { exit 1 }
}

# Step 1: Check for SSH key pair
Write-Step "Checking SSH key pair"

$privateKey = "terraform-key"
$publicKey = "terraform-key.pub"

if ((Test-Path $privateKey) -and (Test-Path $publicKey)) {
    Write-Success "SSH key pair found"
    
    # Show key fingerprint
    try {
        $keyInfo = ssh-keygen -l -f $publicKey 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Info "Key fingerprint: $keyInfo"
        }
    } catch {
        Write-Info "Could not read key fingerprint (ssh-keygen not available)"
    }
} else {
    Write-Warning "SSH key pair not found"
    Write-Host "`nCreating SSH key pair for you..."
    
    try {
        $result = ssh-keygen -t rsa -b 4096 -f $privateKey -N '""' 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "SSH key pair created successfully"
            Write-Info "Private key: $privateKey"
            Write-Info "Public key: $publicKey"
        } else {
            Write-Warning "ssh-keygen failed: $result"
            Write-Host "Please create SSH keys manually:" -ForegroundColor Yellow
            Write-Host "  ssh-keygen -t rsa -b 4096 -f terraform-key -N ''" -ForegroundColor White
            $continue = Read-Host "Continue anyway? (y/N)"
            if ($continue -ne 'y') { exit 1 }
        }
    } catch {
        Write-Warning "ssh-keygen not available: $_"
        Write-Host "Please install OpenSSH or create keys manually" -ForegroundColor Yellow
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne 'y') { exit 1 }
    }
}

# Step 2: Check variables configuration
Write-Step "Checking variables configuration"

if (Test-Path "terraform.tfvars") {
    Write-Success "terraform.tfvars found"
    Write-Info "Using custom variable values"
} else {
    Write-Info "terraform.tfvars not found - using defaults"
    Write-Host "You can create terraform.tfvars to customize:" -ForegroundColor Gray
    Write-Host "  cp terraform.tfvars.example terraform.tfvars" -ForegroundColor White
    
    $customize = Read-Host "Would you like to create terraform.tfvars now? (y/N)"
    if ($customize -eq 'y') {
        try {
            Copy-Item "terraform.tfvars.example" "terraform.tfvars"
            Write-Success "Created terraform.tfvars from example"
            Write-Info "You can edit this file to customize instance settings"
        } catch {
            Write-Warning "Could not copy terraform.tfvars.example: $_"
        }
    }
}

# Step 3: Check OpenStack connectivity
Write-Step "Verifying OpenStack connectivity"

$hasCredentials = $false
$osVars = @("OS_AUTH_URL", "OS_USERNAME", "OS_PASSWORD", "OS_PROJECT_NAME")
foreach ($var in $osVars) {
    if (Get-Item "env:$var" -ErrorAction SilentlyContinue) {
        $hasCredentials = $true
        break
    }
}

if ($hasCredentials) {
    Write-Success "OpenStack credentials detected"
} else {
    Write-Warning "No OpenStack environment variables detected"
    Write-Info "Make sure you've set up authentication (see Exercise 1)"
}

# Step 4: Initialize Terraform
Write-Step "Initializing Terraform"

if (Test-Path ".terraform") {
    Write-Info "Terraform already initialized"
} else {
    try {
        $initOutput = terraform init 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Terraform initialized successfully"
        } else {
            Write-Warning "Terraform init had issues: $initOutput"
        }
    } catch {
        Write-Host "❌ Terraform init failed: $_" -ForegroundColor Red
        exit 1
    }
}

# Step 5: Validate configuration
Write-Step "Validating Terraform configuration"

try {
    $validateOutput = terraform validate 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Configuration is valid"
    } else {
        Write-Host "❌ Validation failed: $validateOutput" -ForegroundColor Red
        Write-Host "`n🔍 Common issues:" -ForegroundColor Yellow
        Write-Host "• Check that terraform-key.pub exists"
        Write-Host "• Verify all file paths are correct"
        Write-Host "• Ensure syntax is correct in all .tf files"
        exit 1
    }
} catch {
    Write-Host "❌ Validation error: $_" -ForegroundColor Red
    exit 1
}

# Step 6: Plan the deployment
Write-Step "Creating Terraform plan"

Write-Info "This will show what resources will be created..."

try {
    $planOutput = terraform plan -detailed-exitcode 2>&1
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Info "No changes needed (infrastructure already exists)"
    } elseif ($exitCode -eq 2) {
        Write-Success "Plan completed successfully"
        Write-Info "Resources to be created:"
        Write-Host "  • Virtual Machine (Ubuntu 22.04)" -ForegroundColor White
        Write-Host "  • Security Group (SSH, HTTP, HTTPS, ICMP)" -ForegroundColor White  
        Write-Host "  • SSH Key Pair" -ForegroundColor White
        Write-Host "  • Optional Floating IP" -ForegroundColor White
    } else {
        Write-Host "❌ Planning failed:" -ForegroundColor Red
        Write-Host $planOutput -ForegroundColor Red
        
        Write-Host "`n🔍 Common issues:" -ForegroundColor Yellow
        Write-Host "• Image name not found (try 'ubuntu-22.04' or check available images)"
        Write-Host "• Flavor name not available (try 'm1.tiny' or 'standard.small')"
        Write-Host "• Network name incorrect (try 'private' or 'default')"
        Write-Host "• SSH public key file not found"
        
        exit 1
    }
} catch {
    Write-Host "❌ Planning error: $_" -ForegroundColor Red
    exit 1
}

# Step 7: Apply the configuration
Write-Step "Deploying the virtual machine"

Write-Info "This will create your VM and associated resources in OpenStack"
Write-Warning "This may take a few minutes as the VM boots and runs user-data scripts"

if (-not $AutoApprove) {
    $apply = Read-Host "Deploy the virtual machine? (y/N)"
    if ($apply -ne 'y') { 
        Write-Host "Deployment cancelled" -ForegroundColor Yellow
        exit 0
    }
}

try {
    Write-Info "Starting deployment... (this may take 2-5 minutes)"
    $applyOutput = terraform apply -auto-approve 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Virtual machine deployed successfully!"
    } else {
        Write-Host "❌ Deployment failed: $applyOutput" -ForegroundColor Red
        
        Write-Host "`n🔍 Troubleshooting:" -ForegroundColor Yellow
        Write-Host "• Check OpenStack quotas (VMs, floating IPs, security groups)"
        Write-Host "• Verify network availability"
        Write-Host "• Ensure image and flavor exist in your project"
        Write-Host "• Check for resource naming conflicts"
        
        exit 1
    }
} catch {
    Write-Host "❌ Deployment error: $_" -ForegroundColor Red
    exit 1
}

# Step 8: Display results and connection info
Write-Step "Displaying connection information"

try {
    $outputs = terraform output -json | ConvertFrom-Json
    
    if ($outputs.instance_info) {
        Write-Host "`n🖥️  Virtual Machine Information:" -ForegroundColor Green
        $instance = $outputs.instance_info.value
        Write-Host "  Name: $($instance.name)" -ForegroundColor White
        Write-Host "  Status: $($instance.status)" -ForegroundColor White
        Write-Host "  Private IP: $($instance.private_ip)" -ForegroundColor White
        if ($instance.floating_ip) {
            Write-Host "  Public IP: $($instance.floating_ip)" -ForegroundColor White
        }
        Write-Host "  Image: $($instance.image)" -ForegroundColor White
        Write-Host "  Flavor: $($instance.flavor)" -ForegroundColor White
    }
    
    if ($outputs.connection_info) {
        Write-Host "`n🔗 Connection Commands:" -ForegroundColor Green
        $connection = $outputs.connection_info.value
        Write-Host "  SSH: $($connection.ssh_command)" -ForegroundColor Cyan
        Write-Host "  Web: $($connection.web_url)" -ForegroundColor Cyan
        Write-Host "  Ping: $($connection.ping_test)" -ForegroundColor Cyan
        
        if ($connection.note) {
            Write-Info $connection.note
        }
    }
    
    if ($outputs.security_group_info) {
        Write-Host "`n🔒 Security Group:" -ForegroundColor Green
        $sg = $outputs.security_group_info.value
        Write-Host "  Name: $($sg.name)" -ForegroundColor White
        Write-Host "  Rules: $($sg.rules_count) configured" -ForegroundColor White
    }
    
} catch {
    Write-Warning "Could not parse terraform outputs: $_"
    Write-Info "Run 'terraform output' to see connection details"
}

# Step 9: Test connectivity
Write-Step "Testing connectivity"

try {
    $outputs = terraform output -json | ConvertFrom-Json
    $connectionInfo = $outputs.connection_info.value
    
    # Extract IP address from connection info
    $ipAddress = $null
    if ($connectionInfo.ssh_command -match '@([0-9.]+)') {
        $ipAddress = $matches[1]
    }
    
    if ($ipAddress) {
        Write-Info "Testing ping connectivity to $ipAddress"
        $pingResult = Test-Connection -ComputerName $ipAddress -Count 2 -Quiet 2>$null
        if ($pingResult) {
            Write-Success "Ping test successful!"
        } else {
            Write-Warning "Ping test failed (may be normal if ICMP is filtered)"
        }
        
        # Test HTTP if web server should be available
        Write-Info "Testing web server availability"
        try {
            $webResponse = Invoke-WebRequest -Uri "http://$ipAddress" -TimeoutSec 10 -UseBasicParsing 2>$null
            if ($webResponse.StatusCode -eq 200) {
                Write-Success "Web server is responding!"
                Write-Info "Visit http://$ipAddress to see your deployed application"
            }
        } catch {
            Write-Warning "Web server not yet available (VM may still be initializing)"
            Write-Info "Wait a few minutes and try: curl http://$ipAddress"
        }
    }
} catch {
    Write-Info "Connectivity testing skipped (could not extract IP address)"
}

# Summary and next steps
Write-Host "`n" -NoNewline
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ VIRTUAL MACHINE DEPLOYED SUCCESSFULLY!                     ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n🎉 Congratulations! You have successfully:" -ForegroundColor Cyan
Write-Host "  • Created a virtual machine in OpenStack"
Write-Host "  • Configured security groups for network access"
Write-Host "  • Set up SSH key authentication"
Write-Host "  • Deployed automated configuration via user-data"
Write-Host "  • Established network connectivity"

Write-Host "`n🔧 Your VM includes:" -ForegroundColor Yellow
Write-Host "  • Ubuntu 22.04 LTS operating system"
Write-Host "  • Nginx web server with custom welcome page"
Write-Host "  • SSH access via your private key"
Write-Host "  • Security groups allowing SSH, HTTP, HTTPS, and ping"
Write-Host "  • System monitoring endpoints"

Write-Host "`n🌐 Try these commands:" -ForegroundColor Cyan
Write-Host "  # View all connection details"
Write-Host "  terraform output" -ForegroundColor White
Write-Host ""
Write-Host "  # Connect via SSH"
Write-Host "  ssh -i terraform-key ubuntu@<ip-address>" -ForegroundColor White
Write-Host ""
Write-Host "  # Test web server"
Write-Host "  curl http://<ip-address>" -ForegroundColor White
Write-Host ""
Write-Host "  # Check system status"
Write-Host "  curl http://<ip-address>/system-info" -ForegroundColor White

Write-Host "`n🚀 Next Steps:" -ForegroundColor Yellow
Write-Host "  • Explore your VM via SSH and web interface"
Write-Host "  • Move to Exercise 3: Advanced Networking"
Write-Host "  • cd ../03-networking"
Write-Host "  • ./interactive-guide.ps1"

Write-Host "`n💡 What You Learned:" -ForegroundColor Cyan
Write-Host "  • OpenStack compute instance creation"
Write-Host "  • Security group configuration and network rules"  
Write-Host "  • SSH key pair management"
Write-Host "  • VM automation with user-data scripts"
Write-Host "  • Floating IP assignment for external access"
Write-Host "  • Resource tagging and metadata"

Write-Host "`n🧹 Cleanup:" -ForegroundColor Gray
Write-Host "  When ready, run 'terraform destroy' to remove all resources"

$nextExercise = Read-Host "`nProceed to Exercise 3 (Networking)? (Y/n)"
if ($nextExercise -ne 'n') {
    if (Test-Path "../03-networking/interactive-guide.ps1") {
        Write-Host "`nMoving to Exercise 3..." -ForegroundColor Green
        Set-Location "../03-networking"
        & "./interactive-guide.ps1"
    } else {
        Write-Host "Exercise 3 not found. Please navigate manually." -ForegroundColor Yellow
    }
}