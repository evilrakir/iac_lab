# LabValidation.psm1 - Exercise validation framework for Terraform Lab

function Test-TerraformState {
    <#
    .SYNOPSIS
        Validates Terraform state exists and contains expected resources
    #>
    param(
        [string]$WorkingDirectory = (Get-Location),
        [string[]]$ExpectedResources = @()
    )
    
    $stateFile = Join-Path $WorkingDirectory "terraform.tfstate"
    
    if (-not (Test-Path $stateFile)) {
        return @{
            Success = $false
            Message = "No terraform.tfstate file found. Run 'terraform apply' first."
        }
    }
    
    try {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
        
        if ($ExpectedResources.Count -gt 0) {
            $resources = $state.resources | ForEach-Object { $_.type + "." + $_.name }
            $missing = $ExpectedResources | Where-Object { $_ -notin $resources }
            
            if ($missing) {
                return @{
                    Success = $false
                    Message = "Missing expected resources: $($missing -join ', ')"
                }
            }
        }
        
        return @{
            Success = $true
            Message = "State file valid with $($state.resources.Count) resources"
        }
    }
    catch {
        return @{
            Success = $false
            Message = "Error reading state file: $_"
        }
    }
}

function Test-TerraformInit {
    <#
    .SYNOPSIS
        Checks if terraform init has been run
    #>
    param(
        [string]$WorkingDirectory = (Get-Location)
    )
    
    $terraformDir = Join-Path $WorkingDirectory ".terraform"
    $lockFile = Join-Path $WorkingDirectory ".terraform.lock.hcl"
    
    if ((Test-Path $terraformDir) -and (Test-Path $lockFile)) {
        return @{
            Success = $true
            Message = "Terraform initialized"
        }
    }
    
    return @{
        Success = $false
        Message = "Run 'terraform init' to initialize the working directory"
    }
}

function Test-DockerContainer {
    <#
    .SYNOPSIS
        Validates Docker containers are running as expected
    #>
    param(
        [string[]]$ContainerNames = @(),
        [switch]$RequireHealthy
    )
    
    # Check Docker is running
    $dockerTest = docker version 2>$null
    if (-not $?) {
        return @{
            Success = $false
            Message = "Docker is not running. Start Docker Desktop first."
        }
    }
    
    $results = @()
    foreach ($name in $ContainerNames) {
        $container = docker ps --filter "name=$name" --format "json" 2>$null | ConvertFrom-Json
        
        if (-not $container) {
            $results += "Container '$name' not found or not running"
        }
        elseif ($RequireHealthy -and $container.Status -notmatch "healthy") {
            $results += "Container '$name' is not healthy: $($container.Status)"
        }
    }
    
    if ($results.Count -eq 0) {
        return @{
            Success = $true
            Message = "All containers running as expected"
        }
    }
    
    return @{
        Success = $false
        Message = $results -join "; "
    }
}

function Test-KubernetesResource {
    <#
    .SYNOPSIS
        Validates Kubernetes resources exist
    #>
    param(
        [string]$Namespace = "default",
        [string]$ResourceType = "pod",
        [string]$ResourceName,
        [string]$LabelSelector
    )
    
    # Check kubectl is available
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        return @{
            Success = $false
            Message = "kubectl not found. Install kubectl first."
        }
    }
    
    # Check cluster connection
    $nodes = kubectl get nodes 2>$null
    if (-not $?) {
        return @{
            Success = $false
            Message = "Cannot connect to Kubernetes cluster. Check your kubeconfig."
        }
    }
    
    $cmd = "kubectl get $ResourceType -n $Namespace"
    if ($ResourceName) {
        $cmd += " $ResourceName"
    }
    if ($LabelSelector) {
        $cmd += " -l $LabelSelector"
    }
    
    $result = Invoke-Expression "$cmd 2>&1"
    
    if ($LASTEXITCODE -eq 0) {
        return @{
            Success = $true
            Message = "Kubernetes $ResourceType found in namespace $Namespace"
        }
    }
    
    return @{
        Success = $false
        Message = "Kubernetes $ResourceType not found: $result"
    }
}

function Test-FileContent {
    <#
    .SYNOPSIS
        Validates file exists and contains expected content
    #>
    param(
        [string]$FilePath,
        [string[]]$MustContain = @(),
        [string[]]$MustNotContain = @(),
        [switch]$ValidateJson,
        [switch]$ValidateYaml
    )
    
    if (-not (Test-Path $FilePath)) {
        return @{
            Success = $false
            Message = "File not found: $FilePath"
        }
    }
    
    $content = Get-Content $FilePath -Raw
    
    # Validate format
    if ($ValidateJson) {
        try {
            $null = $content | ConvertFrom-Json
        }
        catch {
            return @{
                Success = $false
                Message = "Invalid JSON in $FilePath"
            }
        }
    }
    
    if ($ValidateYaml) {
        # Basic YAML validation (check for common issues)
        if ($content -match '^\t') {
            return @{
                Success = $false
                Message = "YAML file contains tabs (use spaces instead)"
            }
        }
    }
    
    # Check required content
    foreach ($required in $MustContain) {
        if ($content -notmatch [regex]::Escape($required)) {
            return @{
                Success = $false
                Message = "File missing required content: '$required'"
            }
        }
    }
    
    # Check forbidden content
    foreach ($forbidden in $MustNotContain) {
        if ($content -match [regex]::Escape($forbidden)) {
            return @{
                Success = $false
                Message = "File contains forbidden content: '$forbidden'"
            }
        }
    }
    
    return @{
        Success = $true
        Message = "File content validated"
    }
}

function Test-TerraformOutput {
    <#
    .SYNOPSIS
        Validates Terraform outputs exist and have expected values
    #>
    param(
        [string]$WorkingDirectory = (Get-Location),
        [hashtable]$ExpectedOutputs = @{}
    )
    
    Push-Location $WorkingDirectory
    try {
        $outputs = terraform output -json 2>$null | ConvertFrom-Json
        
        if (-not $?) {
            return @{
                Success = $false
                Message = "Failed to get Terraform outputs. Run 'terraform apply' first."
            }
        }
        
        $failures = @()
        foreach ($key in $ExpectedOutputs.Keys) {
            if (-not $outputs.$key) {
                $failures += "Missing output: $key"
            }
            elseif ($ExpectedOutputs[$key] -and $outputs.$key.value -ne $ExpectedOutputs[$key]) {
                $failures += "Output '$key' has unexpected value"
            }
        }
        
        if ($failures.Count -eq 0) {
            return @{
                Success = $true
                Message = "All outputs validated"
            }
        }
        
        return @{
            Success = $false
            Message = $failures -join "; "
        }
    }
    finally {
        Pop-Location
    }
}

function Test-ServiceEndpoint {
    <#
    .SYNOPSIS
        Tests if a service endpoint is accessible
    #>
    param(
        [string]$Uri,
        [int]$ExpectedStatusCode = 200,
        [int]$TimeoutSeconds = 5
    )
    
    try {
        $response = Invoke-WebRequest -Uri $Uri -TimeoutSec $TimeoutSeconds -UseBasicParsing
        
        if ($response.StatusCode -eq $ExpectedStatusCode) {
            return @{
                Success = $true
                Message = "Endpoint accessible: $Uri"
            }
        }
        
        return @{
            Success = $false
            Message = "Unexpected status code: $($response.StatusCode)"
        }
    }
    catch {
        return @{
            Success = $false
            Message = "Cannot reach endpoint: $_"
        }
    }
}

function Test-CloudCredentials {
    <#
    .SYNOPSIS
        Validates cloud provider credentials are configured
    #>
    param(
        [ValidateSet("AWS", "Azure", "GCP")]
        [string]$Provider
    )
    
    switch ($Provider) {
        "AWS" {
            $identity = aws sts get-caller-identity 2>$null
            if ($?) {
                return @{
                    Success = $true
                    Message = "AWS credentials configured"
                }
            }
            return @{
                Success = $false
                Message = "AWS credentials not configured. Run 'aws configure'"
            }
        }
        "Azure" {
            $account = az account show 2>$null
            if ($?) {
                return @{
                    Success = $true
                    Message = "Azure credentials configured"
                }
            }
            return @{
                Success = $false
                Message = "Azure credentials not configured. Run 'az login'"
            }
        }
        "GCP" {
            $account = gcloud auth list --format=json 2>$null | ConvertFrom-Json
            if ($account) {
                return @{
                    Success = $true
                    Message = "GCP credentials configured"
                }
            }
            return @{
                Success = $false
                Message = "GCP credentials not configured. Run 'gcloud auth login'"
            }
        }
    }
}

function Show-ValidationReport {
    <#
    .SYNOPSIS
        Displays a formatted validation report
    #>
    param(
        [hashtable[]]$Results
    )
    
    Write-Host "`n╔══════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       VALIDATION REPORT              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $passed = 0
    $failed = 0
    
    foreach ($result in $Results) {
        if ($result.Success) {
            Write-Host "  ✅ " -NoNewline -ForegroundColor Green
            Write-Host $result.Message
            $passed++
        }
        else {
            Write-Host "  ❌ " -NoNewline -ForegroundColor Red
            Write-Host $result.Message
            $failed++
        }
    }
    
    Write-Host ""
    Write-Host "Summary: " -NoNewline
    Write-Host "$passed passed" -ForegroundColor Green -NoNewline
    Write-Host ", " -NoNewline
    Write-Host "$failed failed" -ForegroundColor Red
    
    return ($failed -eq 0)
}

# Export functions
Export-ModuleMember -Function @(
    'Test-TerraformState',
    'Test-TerraformInit',
    'Test-DockerContainer',
    'Test-KubernetesResource',
    'Test-FileContent',
    'Test-TerraformOutput',
    'Test-ServiceEndpoint',
    'Test-CloudCredentials',
    'Show-ValidationReport'
)