#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive Terraform Learning Lab

.DESCRIPTION
    An interactive, guided learning experience for Terraform with real-time validation,
    hints, progress tracking, and hands-on exercises. Designed specifically for 
    PowerShell developers learning Terraform.
#>

[CmdletBinding()]
param(
    [string]$Exercise = "",
    [switch]$ShowStats,
    [switch]$SkipPrerequisites,
    [switch]$ResetProgress
)

$ErrorActionPreference = "Stop"

# Configuration
$script:LabRoot = $PSScriptRoot
$script:TerraformPath = "C:\Tools\Terraform\terraform.exe"
# Store progress in user's AppData folder, not in the repo
$script:ProgressFile = Join-Path $env:APPDATA "TerraformLab\progress.json"

# Progress tracking
$script:Progress = @{
    UserName = ""
    CompletedExercises = @()
    TotalScore = 0
}

# Exercise definitions
$script:Exercises = @{
    # 01-basics - Core Terraform Concepts
    "01-basics/01-hello-world" = @{
        Name = "Hello World - Your First Terraform Configuration"
        Description = "Learn basic Terraform syntax, workflow, and create your first resources"
        Prerequisites = @()
        Difficulty = "Beginner"
    }
    "01-basics/02-variables" = @{
        Name = "Variables and Input Values - All Types"
        Description = "Master all variable types, validation, locals, and precedence"
        Prerequisites = @("01-basics/01-hello-world")
        Difficulty = "Beginner"
    }
    "01-basics/03-outputs" = @{
        Name = "Outputs and Data Sharing"
        Description = "Learn to expose values and share data between configurations"
        Prerequisites = @("01-basics/02-variables")
        Difficulty = "Beginner"
    }
    "01-basics/04-data-sources" = @{
        Name = "Data Sources - Reading External Data"
        Description = "Query existing resources and read external data files"
        Prerequisites = @("01-basics/03-outputs")
        Difficulty = "Intermediate"
    }
    "01-basics/05-resources" = @{
        Name = "Resource Patterns and Dependencies"
        Description = "Master resource lifecycle, explicit/implicit dependencies"
        Prerequisites = @("01-basics/04-data-sources")
        Difficulty = "Intermediate"
    }
    
    # 02-providers - Working with Providers
    "02-providers/01-local-provider" = @{
        Name = "Local Provider Deep Dive"
        Description = "Master the local provider for file and script operations"
        Prerequisites = @("01-basics/05-resources")
        Difficulty = "Intermediate"
    }
    
    # 03-modules - Reusable Infrastructure
    "03-modules/01-simple-module" = @{
        Name = "Your First Module"
        Description = "Create a reusable Terraform module"
        Prerequisites = @("02-providers/01-local-provider")
        Difficulty = "Intermediate"
    }
    
    # 04-state - State Management
    "04-state/01-local-state" = @{
        Name = "Understanding Terraform State"
        Description = "Learn how Terraform tracks infrastructure state"
        Prerequisites = @("03-modules/01-simple-module")
        Difficulty = "Intermediate"
    }
    
    # 06-advanced - Advanced Patterns
    "06-advanced/02-conditional-resources" = @{
        Name = "Conditional Resources and Dynamic Blocks"
        Description = "Create resources conditionally and use dynamic blocks"
        Prerequisites = @("04-state/01-local-state")
        Difficulty = "Advanced"
    }
    # 03-openstack - OpenStack Labs
    "03-openstack/01-provider-setup" = @{
        Name = "OpenStack Provider Configuration"
        Description = "Configure OpenStack provider and test cloud connectivity"
        Prerequisites = @("02-providers/01-local-provider")
        Difficulty = "Intermediate"
    }
    "03-openstack/02-basic-vm" = @{
        Name = "OpenStack Virtual Machine Deployment"
        Description = "Deploy your first VM with security groups and SSH access"
        Prerequisites = @("03-openstack/01-provider-setup")
        Difficulty = "Intermediate"
    }
    "03-openstack/03-networking" = @{
        Name = "Advanced Networking and Security Groups"
        Description = "Create multi-tier network architecture with bastion host"
        Prerequisites = @("03-openstack/02-basic-vm")
        Difficulty = "Intermediate"
    }
    "03-openstack/04-storage" = @{
        Name = "Storage and Volume Management"
        Description = "Implement persistent storage with monitoring and backups"
        Prerequisites = @("03-openstack/03-networking")
        Difficulty = "Intermediate"
    }
    "03-openstack/05-load-balancer" = @{
        Name = "Load Balancers and High Availability"
        Description = "Configure load balancing and health checks for web applications"
        Prerequisites = @("03-openstack/04-storage")
        Difficulty = "Advanced"
    }

    # 02-providers - Working with Providers (continued)
    "02-providers/02-aws-basics" = @{
        Name = "AWS Provider Basics"
        Description = "Introduction to AWS cloud infrastructure with Terraform"
        Prerequisites = @("02-providers/01-local-provider")
        Difficulty = "Intermediate"
    }
    "02-providers/03-azure-basics" = @{
        Name = "Azure Provider Basics"
        Description = "Deploy Azure resources with Terraform (resource groups, VMs, networking)"
        Prerequisites = @("02-providers/01-local-provider")
        Difficulty = "Intermediate"
    }
    "02-providers/04-gcp-basics" = @{
        Name = "GCP Provider Basics"
        Description = "Google Cloud Platform infrastructure with Terraform"
        Prerequisites = @("02-providers/01-local-provider")
        Difficulty = "Intermediate"
    }
    "02-providers/05-windows-provider" = @{
        Name = "Windows-Specific Providers"
        Description = "Active Directory, DNS, and DHCP management with Terraform"
        Prerequisites = @("02-providers/01-local-provider")
        Difficulty = "Advanced"
    }
    "02-providers/06-openstack" = @{
        Name = "OpenStack Provider"
        Description = "Private cloud infrastructure with the OpenStack provider"
        Prerequisites = @("02-providers/01-local-provider")
        Difficulty = "Intermediate"
    }

    # 03-modules - Reusable Infrastructure (continued)
    "03-modules/02-module-variables" = @{
        Name = "Module Input Variables"
        Description = "Parameterize modules with input variables and validation"
        Prerequisites = @("03-modules/01-simple-module")
        Difficulty = "Intermediate"
    }
    "03-modules/03-module-sources" = @{
        Name = "Module Sources"
        Description = "Load modules from local paths, Git repos, and registries"
        Prerequisites = @("03-modules/02-module-variables")
        Difficulty = "Intermediate"
    }
    "03-modules/04-module-registry" = @{
        Name = "Terraform Module Registry"
        Description = "Use and publish modules from the Terraform Registry"
        Prerequisites = @("03-modules/03-module-sources")
        Difficulty = "Intermediate"
    }
    "03-modules/05-windows-module" = @{
        Name = "Windows Infrastructure Modules"
        Description = "Build reusable modules for Windows infrastructure patterns"
        Prerequisites = @("03-modules/03-module-sources")
        Difficulty = "Advanced"
    }

    # 04-state - State Management (continued)
    "04-state/02-remote-state" = @{
        Name = "Remote State Backends"
        Description = "Configure S3, Azure Storage, and GCS remote state backends"
        Prerequisites = @("04-state/01-local-state")
        Difficulty = "Intermediate"
    }
    "04-state/03-state-locking" = @{
        Name = "State Locking and Concurrency"
        Description = "Prevent concurrent modifications with state locking"
        Prerequisites = @("04-state/02-remote-state")
        Difficulty = "Intermediate"
    }
    "04-state/04-workspaces" = @{
        Name = "Terraform Workspaces"
        Description = "Manage multiple environments with workspaces"
        Prerequisites = @("04-state/02-remote-state")
        Difficulty = "Intermediate"
    }
    "04-state/05-gitops-workflow" = @{
        Name = "GitOps Workflow with Terraform"
        Description = "Implement Git-based infrastructure deployment workflows"
        Prerequisites = @("04-state/04-workspaces")
        Difficulty = "Advanced"
    }

    # 05-best-practices - Production Patterns
    "05-best-practices/01-project-structure" = @{
        Name = "Project Structure and Organization"
        Description = "Organize Terraform projects for maintainability and scale"
        Prerequisites = @("04-state/01-local-state")
        Difficulty = "Intermediate"
    }
    "05-best-practices/02-naming-conventions" = @{
        Name = "Resource Naming Conventions"
        Description = "Establish consistent naming patterns across infrastructure"
        Prerequisites = @("05-best-practices/01-project-structure")
        Difficulty = "Intermediate"
    }
    "05-best-practices/03-security" = @{
        Name = "Security Best Practices"
        Description = "Secure Terraform configurations, secrets management, and IAM"
        Prerequisites = @("05-best-practices/01-project-structure")
        Difficulty = "Intermediate"
    }
    "05-best-practices/04-cost-optimization" = @{
        Name = "Cost Optimization Strategies"
        Description = "Reduce cloud costs with Terraform patterns and Infracost"
        Prerequisites = @("05-best-practices/01-project-structure")
        Difficulty = "Intermediate"
    }
    "05-best-practices/05-monitoring-integration" = @{
        Name = "Monitoring and Observability Integration"
        Description = "Deploy monitoring infrastructure with Terraform (CloudWatch, Datadog, Grafana)"
        Prerequisites = @("05-best-practices/01-project-structure")
        Difficulty = "Advanced"
    }

    # 06-advanced - Advanced Patterns (continued)
    "06-advanced/01-dynamic-blocks" = @{
        Name = "Dynamic Blocks"
        Description = "Generate repeated nested blocks dynamically from data"
        Prerequisites = @("04-state/01-local-state")
        Difficulty = "Advanced"
    }
    "06-advanced/03-terraform-functions" = @{
        Name = "Terraform Built-in Functions"
        Description = "Master string, collection, numeric, and encoding functions"
        Prerequisites = @("06-advanced/01-dynamic-blocks")
        Difficulty = "Advanced"
    }
    "06-advanced/04-custom-providers" = @{
        Name = "Custom Terraform Providers"
        Description = "Understand provider architecture and build custom providers"
        Prerequisites = @("06-advanced/03-terraform-functions")
        Difficulty = "Advanced"
    }
    "06-advanced/05-powershell-integration" = @{
        Name = "PowerShell and Terraform Integration"
        Description = "Deep integration patterns between PowerShell and Terraform"
        Prerequisites = @("06-advanced/01-dynamic-blocks")
        Difficulty = "Advanced"
    }

    # 07-containers - Container Orchestration
    "07-containers/01-docker-basics" = @{
        Name = "Docker with Terraform"
        Description = "Container infrastructure as code with the Docker provider"
        Prerequisites = @("02-providers/01-local-provider")
        Difficulty = "Intermediate"
    }
    "07-containers/01-docker-provider" = @{
        Name = "Docker Provider Deep Dive"
        Description = "Managing containers, networks, and volumes with Terraform"
        Prerequisites = @("07-containers/01-docker-basics")
        Difficulty = "Intermediate"
    }
    "07-containers/02-kubernetes-basics" = @{
        Name = "Kubernetes Provider Basics"
        Description = "Manage Kubernetes resources (deployments, services, config) with Terraform"
        Prerequisites = @("07-containers/01-docker-provider")
        Difficulty = "Intermediate"
    }
    "07-containers/03-helm-terraform" = @{
        Name = "Helm Charts with Terraform"
        Description = "Deploy and manage Helm releases using the Helm provider"
        Prerequisites = @("07-containers/02-kubernetes-basics")
        Difficulty = "Advanced"
    }
    "07-containers/04-local-k8s" = @{
        Name = "Local Kubernetes Development"
        Description = "Set up local K8s clusters (kind, minikube, k3s) with Terraform"
        Prerequisites = @("07-containers/02-kubernetes-basics")
        Difficulty = "Intermediate"
    }
    "07-containers/05-cloud-k8s" = @{
        Name = "Cloud Kubernetes (EKS, AKS, GKE)"
        Description = "Deploy managed Kubernetes on AWS, Azure, and GCP"
        Prerequisites = @("07-containers/02-kubernetes-basics")
        Difficulty = "Advanced"
    }

    # 08-integrations - Tool Integration
    "08-integrations/01-terraform-ansible" = @{
        Name = "Terraform + Ansible Integration"
        Description = "Combine Terraform provisioning with Ansible configuration management"
        Prerequisites = @("06-advanced/02-conditional-resources")
        Difficulty = "Intermediate"
    }
    "08-integrations/02-docker-compose" = @{
        Name = "Docker Compose Integration"
        Description = "Compare and integrate Docker Compose with Terraform workflows"
        Prerequisites = @("07-containers/01-docker-provider")
        Difficulty = "Intermediate"
    }
    "08-integrations/03-cicd-pipelines" = @{
        Name = "CI/CD Pipeline Integration"
        Description = "Run Terraform in GitHub Actions, Azure DevOps, and GitLab pipelines"
        Prerequisites = @("05-best-practices/01-project-structure")
        Difficulty = "Advanced"
    }
    "08-integrations/04-full-stack" = @{
        Name = "Full Stack Application Deployment (Capstone)"
        Description = "End-to-end infrastructure + application deployment bringing everything together"
        Prerequisites = @("08-integrations/03-cicd-pipelines")
        Difficulty = "Advanced"
    }

    # 09-legacy-optional - Legacy Tool Integration
    "09-legacy-optional/01-vagrant" = @{
        Name = "Vagrant Provider (Legacy)"
        Description = "Vagrant integration patterns and migration strategies"
        Prerequisites = @("02-providers/01-local-provider")
        Difficulty = "Intermediate"
    }
    "09-legacy-optional/02-chef-puppet" = @{
        Name = "Chef and Puppet Integration (Legacy)"
        Description = "Integration patterns and migration strategies for Chef/Puppet users"
        Prerequisites = @("08-integrations/01-terraform-ansible")
        Difficulty = "Intermediate"
    }
    "09-legacy-optional/03-on-premise" = @{
        Name = "On-Premise Infrastructure (Legacy)"
        Description = "Managing VMware, Hyper-V, and hybrid infrastructure with Terraform"
        Prerequisites = @("02-providers/05-windows-provider")
        Difficulty = "Intermediate"
    }
}

# Helper Functions
function Write-Success { 
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green 
}

function Write-Info { 
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan 
}

function Write-Warning { 
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow 
}

function Write-Error { 
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red 
}

function Show-Header {
    param([string]$Title, [string]$Subtitle = "")
    
    Clear-Host
    $line = "=" * 60
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor Yellow
    if ($Subtitle) {
        Write-Host "  $Subtitle" -ForegroundColor White
    }
    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
}

function Test-TerraformInstallation {
    if (-not (Test-Path $script:TerraformPath)) {
        Write-Error "Terraform not found at $script:TerraformPath"
        return $false
    }
    
    try {
        $version = & $script:TerraformPath version
        Write-Success "Terraform found: $($version[0])"
        return $true
    } catch {
        Write-Error "Error running Terraform: $($_.Exception.Message)"
        return $false
    }
}

function Show-Menu {
    param([array]$Options, [string]$Prompt = "Select an option")
    
    for ($i = 0; $i -lt $Options.Length; $i++) {
        Write-Host "  $($i + 1). $($Options[$i])" -ForegroundColor White
    }
    Write-Host ""
    
    do {
        $selection = Read-Host $Prompt
        if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $Options.Length) {
            return [int]$selection - 1
        }
        Write-Warning "Please enter a number between 1 and $($Options.Length)"
    } while ($true)
}

function Test-Prerequisites {
    param([string]$ExerciseId)
    
    # Skip prerequisite check if override is set
    if ($script:SkipPrerequisites) {
        Write-Warning "Skipping prerequisite check (override enabled)"
        return $true
    }
    
    $exercise = $script:Exercises[$ExerciseId]
    if (-not $exercise.Prerequisites -or $exercise.Prerequisites.Count -eq 0) {
        return $true
    }
    
    $allMet = $true
    foreach ($prereq in $exercise.Prerequisites) {
        if ($script:Progress.CompletedExercises -contains $prereq) {
            Write-Success "Prerequisite met: $prereq"
        } else {
            Write-Error "Prerequisite not met: $prereq"
            $allMet = $false
        }
    }
    
    if (-not $allMet) {
        Write-Host ""
        Write-Warning "TIP: Use -SkipPrerequisites parameter to override prerequisite check"
    }
    
    return $allMet
}

function Invoke-TerraformCommand {
    param(
        [string]$Command, 
        [string]$WorkingDirectory,
        [switch]$AutoApprove  # Add flag for auto-approve
    )
    
    Push-Location $WorkingDirectory
    try {
        # Add auto-approve if specified
        if ($AutoApprove -and $Command -eq "apply") {
            $Command = "apply -auto-approve"
        }
        
        Write-Info "Running: terraform $Command"
        Write-Host ""
        
        # Handle interactive vs non-interactive commands
        if ($Command -match "apply" -and $Command -notmatch "auto-approve") {
            # Interactive apply - use Start-Process to properly handle confirmation prompt
            Write-Host "Running interactive terraform apply..." -ForegroundColor Yellow
            Write-Host "You will be prompted to confirm. Type 'yes' when asked." -ForegroundColor Cyan
            Write-Host ""
            
            $process = Start-Process -FilePath $script:TerraformPath -ArgumentList $Command.Split(' ') -Wait -PassThru -NoNewWindow
            
            if ($process.ExitCode -eq 0) {
                $LASTEXITCODE = 0
            } else {
                $LASTEXITCODE = $process.ExitCode
            }
        } else {
            # Non-interactive commands - stream output directly
            & $script:TerraformPath $Command.Split(' ')
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Success "Command completed successfully"
            return $true
        } else {
            Write-Host ""
            Write-Error "Command failed with exit code $LASTEXITCODE"
            return $false
        }
    } finally {
        Pop-Location
    }
}

function Mark-ExerciseCompleted {
    param([string]$ExerciseId, [string]$WorkspacePath)
    
    # Default to the exercise directory
    if (-not $WorkspacePath) {
        $WorkspacePath = Join-Path $script:LabRoot $ExerciseId
    }
    
    # Count resources in state file
    $resourceCount = 0
    $statePath = Join-Path $WorkspacePath "terraform.tfstate"
    if (Test-Path $statePath) {
        try {
            $state = Get-Content $statePath | ConvertFrom-Json
            if ($state.resources) {
                $resourceCount = $state.resources.Count
            }
        } catch {
            Write-Warning "Could not parse state file for resource count"
        }
    }
    
    # Create completion marker
    $completionMarkerPath = Join-Path $WorkspacePath ".terraform-lab-completed"
    $completionData = @{
        ExerciseId = $ExerciseId
        CompletedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        ResourceCount = $resourceCount
        Method = "TerraformApply"
        LabVersion = "1.0"
    }
    
    try {
        $completionData | ConvertTo-Json | Set-Content $completionMarkerPath
        Write-Success "Exercise marked as completed!"
        Write-Info "Completion marker created: $completionMarkerPath"
        return $true
    } catch {
        Write-Warning "Could not create completion marker: $($_.Exception.Message)"
        return $false
    }
}

function Test-ExerciseCompletion {
    param([string]$ExerciseId, [string]$WorkspacePath)
    
    # Default to the exercise directory
    if (-not $WorkspacePath) {
        $WorkspacePath = Join-Path $script:LabRoot $ExerciseId
    }
    
    # Check for completion marker file first (created when terraform apply succeeds)
    $completionMarkerPath = Join-Path $WorkspacePath ".terraform-lab-completed"
    if (Test-Path $completionMarkerPath) {
        try {
            $completionData = Get-Content $completionMarkerPath | ConvertFrom-Json
            Write-Success "Exercise validation passed: Completed on $($completionData.CompletedAt)"
            Write-Success "Resources created: $($completionData.ResourceCount)"
            return $true
        } catch {
            Write-Warning "Could not parse completion marker file, checking state file..."
        }
    }
    
    # Fallback: Check if terraform.tfstate exists and has resources (for backward compatibility)
    $statePath = Join-Path $WorkspacePath "terraform.tfstate"
    if (Test-Path $statePath) {
        try {
            $state = Get-Content $statePath | ConvertFrom-Json
            if ($state.resources -and $state.resources.Count -gt 0) {
                Write-Success "Exercise validation passed: $($state.resources.Count) resources found in state"
                
                # Create completion marker for future validation
                $completionData = @{
                    ExerciseId = $ExerciseId
                    CompletedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                    ResourceCount = $state.resources.Count
                    Method = "StateFileValidation"
                }
                $completionData | ConvertTo-Json | Set-Content $completionMarkerPath
                Write-Info "Created completion marker for future validation"
                
                return $true
            }
        } catch {
            Write-Warning "Could not parse state file"
        }
    }
    
    Write-Warning "Exercise not yet complete - no completion marker or valid Terraform state found"
    Write-Info "Complete the exercise by successfully running 'terraform apply'"
    return $false
}

function Start-Exercise {
    param([string]$ExerciseId)
    
    $exercise = $script:Exercises[$ExerciseId]
    if (-not $exercise) {
        Write-Error "Exercise not found: $ExerciseId"
        return
    }
    
    $exercisePath = Join-Path $script:LabRoot $ExerciseId
    if (-not (Test-Path $exercisePath)) {
        Write-Error "Exercise directory not found: $exercisePath"
        return
    }
    
    # Use the exercise directory directly
    $workspacePath = $exercisePath
    
    # Clean up any previous Terraform state in the exercise directory
    Push-Location $workspacePath
    try {
        if (Test-Path ".terraform") {
            Write-Info "Cleaning up previous Terraform state..."
            Remove-Item -Path ".terraform" -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path ".terraform.lock.hcl") {
            Write-Info "Removing Terraform lock file..."
            Remove-Item -Path ".terraform.lock.hcl" -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path "terraform.tfstate") {
            Write-Info "Backing up existing state..."
            $backupName = "terraform.tfstate.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item "terraform.tfstate" $backupName -Force
        }
        if (Test-Path "terraform-lab-output") {
            Write-Info "Cleaning up previous output..."
            Remove-Item -Path "terraform-lab-output" -Recurse -Force -ErrorAction SilentlyContinue
        }
    } finally {
        Pop-Location
    }
    
    Show-Header $exercise.Name $exercise.Description
    
    # Check prerequisites
    if (-not (Test-Prerequisites $ExerciseId)) {
        Write-Warning "Please complete prerequisite exercises first."
        Read-Host "Press Enter to continue"
        return
    }
    
    Write-Host "Exercise Directory: $workspacePath" -ForegroundColor Cyan
    Write-Host ""
    Write-Warning "Working directly in the exercise directory."
    Write-Warning "Output files will be created in: $workspacePath\terraform-lab-output"
    Write-Host ""
    
    $ready = Read-Host "Ready to start this exercise? (Y/n)"
    if ($ready -eq 'n') { return }
    
    # Interactive exercise session
    do {
        Show-Header "Exercise: $ExerciseId" "Interactive Session"
        
        $options = @(
            "GUIDED MODE: Step-by-step learning with explanations",
            "View exercise files with explanations",
            "Initialize Terraform (terraform init)",
            "Create execution plan (terraform plan)",
            "Apply changes (terraform apply)",
            "Show current state (terraform show)",
            "Validate exercise completion",
            "Reset this exercise (clean all state/output)",
            "Return to main menu"
        )
        
        $choice = Show-Menu $options "What would you like to do?"
        
        switch ($choice) {
            0 {
                # GUIDED MODE - Full walkthrough with explanations
                Show-Header "GUIDED LEARNING MODE" "Step-by-step with explanations"
                
                Write-Host "Welcome to guided learning mode!" -ForegroundColor Green
                Write-Host "I will explain each concept before we run commands." -ForegroundColor Green
                Write-Host ""
                
                # Step 1: Understand the files
                Write-Host "STEP 1: Understanding the Files" -ForegroundColor Yellow
                Write-Host "================================" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Before running any commands, let us understand what we are working with:" -ForegroundColor White
                Write-Host ""
                
                # Show main.tf with explanation
                if (Test-Path "$exercisePath\main.tf") {
                    Write-Host "main.tf - The Main Configuration" -ForegroundColor Cyan
                    Write-Host "This file defines WHAT infrastructure to create." -ForegroundColor White
                    Write-Host "Think of it like your PowerShell script that creates resources." -ForegroundColor White
                    Write-Host ""
                    Read-Host "Press Enter to see main.tf contents"
                    Get-Content "$exercisePath\main.tf" | Select-Object -First 30 | ForEach-Object {
                        Write-Host "  $_" -ForegroundColor DarkGray
                    }
                    Write-Host ""
                }
                
                # Show variables.tf with explanation
                if (Test-Path "$exercisePath\variables.tf") {
                    Write-Host "variables.tf - Input Parameters" -ForegroundColor Cyan
                    Write-Host "Like PowerShell param() blocks, these are your inputs." -ForegroundColor White
                    Write-Host ""
                    Read-Host "Press Enter to see variables.tf contents"
                    Get-Content "$exercisePath\variables.tf" | Select-Object -First 20 | ForEach-Object {
                        Write-Host "  $_" -ForegroundColor DarkGray
                    }
                    Write-Host ""
                }
                
                Write-Host "Now let us run Terraform commands step by step..." -ForegroundColor Green
                Write-Host ""
                
                # Step 2: terraform init
                Write-Host "STEP 2: Initialize Terraform" -ForegroundColor Yellow
                Write-Host "============================" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "terraform init downloads providers and sets up the directory." -ForegroundColor White
                Write-Host "Like PowerShell Install-Module, this is a one-time setup." -ForegroundColor White
                Write-Host ""
                Write-Host "Type the full command to initialize Terraform:" -ForegroundColor Cyan
                Write-Host "HINT: terraform init" -ForegroundColor DarkGray
                Write-Host ""
                
                do {
                    Write-Host -NoNewline "> " -ForegroundColor Green
                    $userCommand = Read-Host
                    $userCommand = $userCommand.Trim()
                    
                    if ($userCommand -eq "terraform init" -or $userCommand -eq "terraform.exe init") {
                        Write-Host ""
                        Write-Success "Correct! Running terraform init..."
                        Write-Host ""
                        Invoke-TerraformCommand "init" $workspacePath
                        break
                    } elseif ($userCommand -eq "skip") {
                        Write-Host "Skipping this step..." -ForegroundColor Yellow
                        break
                    } else {
                        Write-Warning "Not quite. Type the full command: terraform init"
                        Write-Host "You typed: '$userCommand'" -ForegroundColor Gray
                        Write-Host "Try again or type 'skip' to skip this step" -ForegroundColor Gray
                    }
                } while ($true)
                
                # Step 3: terraform plan
                Write-Host ""
                Write-Host "STEP 3: Preview Changes" -ForegroundColor Yellow
                Write-Host "=======================" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "terraform plan shows what WILL happen without doing it." -ForegroundColor White
                Write-Host "Like PowerShell -WhatIf parameter. Always run this first!" -ForegroundColor White
                Write-Host ""
                Write-Host "Type the full command to preview changes:" -ForegroundColor Cyan
                Write-Host "HINT: terraform plan" -ForegroundColor DarkGray
                Write-Host ""
                
                do {
                    Write-Host -NoNewline "> " -ForegroundColor Green
                    $userCommand = Read-Host
                    $userCommand = $userCommand.Trim()
                    
                    if ($userCommand -eq "terraform plan" -or $userCommand -eq "terraform.exe plan") {
                        Write-Host ""
                        Write-Success "Correct! Running terraform plan..."
                        Write-Host ""
                        Invoke-TerraformCommand "plan" $workspacePath
                        break
                    } elseif ($userCommand -eq "skip") {
                        Write-Host "Skipping this step..." -ForegroundColor Yellow
                        break
                    } else {
                        Write-Warning "Not quite. Type the full command: terraform plan"
                        Write-Host "You typed: '$userCommand'" -ForegroundColor Gray
                        Write-Host "Try again or type 'skip' to skip this step" -ForegroundColor Gray
                    }
                } while ($true)
                
                # Step 4: terraform apply
                Write-Host ""
                Write-Host "STEP 4: Create Resources" -ForegroundColor Yellow
                Write-Host "========================" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "terraform apply actually creates the resources." -ForegroundColor White
                Write-Host "After you run this command, Terraform will show the plan" -ForegroundColor Yellow
                Write-Host "and ask for confirmation. Type 'yes' when prompted." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "TIP: Watch for:" -ForegroundColor Cyan
                Write-Host "  - Resources being created (green +)" -ForegroundColor White
                Write-Host "  - The confirmation prompt (type 'yes' exactly)" -ForegroundColor White
                Write-Host "  - Files created in terraform-lab-output folder" -ForegroundColor White
                Write-Host ""
                Write-Host "Type the full command to create resources:" -ForegroundColor Cyan
                Write-Host "HINT: terraform apply" -ForegroundColor DarkGray
                Write-Host ""
                
                do {
                    Write-Host -NoNewline "> " -ForegroundColor Green
                    $userCommand = Read-Host
                    $userCommand = $userCommand.Trim()
                    
                    if ($userCommand -eq "terraform apply" -or $userCommand -eq "terraform.exe apply") {
                        Write-Host ""
                        Write-Success "Correct! Running terraform apply..."
                        Write-Warning "Remember: Type 'yes' when prompted to confirm!"
                        Write-Host ""
                        $applySuccess = Invoke-TerraformCommand "apply" $workspacePath
                        
                        # Mark exercise complete if apply succeeded
                        if ($applySuccess) {
                            Write-Host ""
                            # Create completion marker
                            if (Mark-ExerciseCompleted $ExerciseId $workspacePath) {
                                Write-Success "*** EXERCISE COMPLETED SUCCESSFULLY! ***"
                                if ($script:Progress.CompletedExercises -notcontains $ExerciseId) {
                                    $script:Progress.CompletedExercises += $ExerciseId
                                    $script:Progress.TotalScore += 100
                                    Save-Progress
                                    Write-Success "Progress saved! Total score: $($script:Progress.TotalScore)"
                                }
                            }
                        }
                        break
                    } elseif ($userCommand -eq "skip") {
                        Write-Host "Skipping this step..." -ForegroundColor Yellow
                        break
                    } else {
                        Write-Warning "Not quite. Type the full command: terraform apply"
                        Write-Host "You typed: '$userCommand'" -ForegroundColor Gray
                        Write-Host "Try again or type 'skip' to skip this step" -ForegroundColor Gray
                    }
                } while ($true)
                
                # Step 5: Show what was created
                Write-Host ""
                Write-Host "STEP 5: Verify What Was Created" -ForegroundColor Yellow
                Write-Host "================================" -ForegroundColor Yellow
                Write-Host ""
                if (Test-Path "$workspacePath\terraform-lab-output") {
                    Write-Host "Files created in terraform-lab-output:" -ForegroundColor Green
                    Get-ChildItem "$workspacePath\terraform-lab-output" -File | ForEach-Object {
                        Write-Host "  - $($_.Name)" -ForegroundColor Cyan
                    }
                    Write-Host ""
                }
                
                Write-Host "Type the full command to see the Terraform state:" -ForegroundColor Cyan
                Write-Host "HINT: terraform show" -ForegroundColor DarkGray
                Write-Host ""
                
                do {
                    Write-Host -NoNewline "> " -ForegroundColor Green
                    $userCommand = Read-Host
                    $userCommand = $userCommand.Trim()
                    
                    if ($userCommand -eq "terraform show" -or $userCommand -eq "terraform.exe show") {
                        Write-Host ""
                        Write-Success "Correct! Running terraform show..."
                        Write-Host ""
                        Invoke-TerraformCommand "show" $workspacePath
                        break
                    } elseif ($userCommand -eq "skip") {
                        Write-Host "Skipping this step..." -ForegroundColor Yellow
                        break
                    } else {
                        Write-Warning "Not quite. Type the full command: terraform show"
                        Write-Host "You typed: '$userCommand'" -ForegroundColor Gray
                        Write-Host "Try again or type 'skip' to skip this step" -ForegroundColor Gray
                    }
                } while ($true)
                
                # Step 6: Clean up (optional)
                Write-Host ""
                Write-Host "STEP 6: Clean Up Resources (Optional)" -ForegroundColor Yellow
                Write-Host "=====================================" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "terraform destroy removes all resources created by Terraform." -ForegroundColor White
                Write-Host "This is like cleanup scripts in PowerShell." -ForegroundColor White
                Write-Host ""
                Write-Host "You can skip this if you want to keep the resources for now." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Type the full command to remove all resources:" -ForegroundColor Cyan
                Write-Host "HINT: terraform destroy" -ForegroundColor DarkGray
                Write-Host ""
                
                do {
                    Write-Host -NoNewline "> " -ForegroundColor Green
                    $userCommand = Read-Host
                    $userCommand = $userCommand.Trim()
                    
                    if ($userCommand -eq "terraform destroy" -or $userCommand -eq "terraform.exe destroy") {
                        Write-Host ""
                        Write-Success "Correct! Running terraform destroy..."
                        Write-Warning "Remember: Type 'yes' when prompted to confirm deletion!"
                        Write-Host ""
                        Invoke-TerraformCommand "destroy" $workspacePath
                        break
                    } elseif ($userCommand -eq "skip") {
                        Write-Host "Skipping cleanup - resources will remain." -ForegroundColor Yellow
                        break
                    } else {
                        Write-Warning "Not quite. Type the full command: terraform destroy"
                        Write-Host "You typed: '$userCommand'" -ForegroundColor Gray
                        Write-Host "Try again or type 'skip' to skip cleanup" -ForegroundColor Gray
                    }
                } while ($true)
                
                Write-Host ""
                Write-Host "Guided walkthrough complete!" -ForegroundColor Green
                Write-Host ""
                Write-Host "You have learned the core Terraform workflow:" -ForegroundColor Yellow
                Write-Host "  1. terraform init    - Initialize the directory" -ForegroundColor White
                Write-Host "  2. terraform plan    - Preview changes" -ForegroundColor White
                Write-Host "  3. terraform apply   - Create resources" -ForegroundColor White
                Write-Host "  4. terraform show    - View current state" -ForegroundColor White
                Write-Host "  5. terraform destroy - Remove resources" -ForegroundColor White
                Write-Host ""
                Write-Host "Your output files are located at:" -ForegroundColor Cyan
                Write-Host "  $workspacePath\terraform-lab-output" -ForegroundColor White
                Write-Host ""
                Write-Host "Practice these commands until they become second nature!" -ForegroundColor Green
            }
            1 {
                # Enhanced file viewing with content display
                Write-Info "Exercise files in $($ExerciseId):"
                Write-Host ""
                
                $tfFiles = Get-ChildItem $exercisePath -File -Filter "*.tf" | Sort-Object Name
                
                foreach ($file in $tfFiles) {
                    Write-Host "FILE: $($file.Name)" -ForegroundColor Yellow
                    Write-Host ("-" * 50) -ForegroundColor DarkGray
                    
                    # Show first 20 lines with comments highlighted
                    $content = Get-Content $file.FullName | Select-Object -First 20
                    $lineNum = 1
                    foreach ($line in $content) {
                        if ($line -match "^#") {
                            # Comment line - show in gray
                            Write-Host "  ${lineNum}: $line" -ForegroundColor DarkGray
                        } elseif ($line -match "^(resource|variable|output|terraform|provider)") {
                            # Terraform keywords - highlight
                            Write-Host "  ${lineNum}: $line" -ForegroundColor Cyan
                        } else {
                            Write-Host "  ${lineNum}: $line" -ForegroundColor White
                        }
                        $lineNum++
                    }
                    
                    $totalLines = (Get-Content $file.FullName).Count
                    if ($totalLines -gt 20) {
                        $moreLines = $totalLines - 20
                        Write-Host "  ... [$moreLines more lines]" -ForegroundColor DarkGray
                    }
                    Write-Host ""
                }
                
                Write-Host "TIP: Read the comments in each file as they explain the concepts!" -ForegroundColor Green
            }
            2 { Invoke-TerraformCommand "init" $workspacePath }
            3 { 
                # Check if providers are initialized before plan
                if (-not (Test-Path "$workspacePath\.terraform")) {
                    Write-Warning "Terraform not initialized. Running terraform init first..."
                    Invoke-TerraformCommand "init" $workspacePath
                    Write-Host ""
                }
                Invoke-TerraformCommand "plan" $workspacePath 
            }
            4 { 
                Write-Warning "This will create resources. Continue? (y/N)"
                if ((Read-Host) -eq 'y') {
                    # Check if providers are initialized
                    if (-not (Test-Path "$workspacePath\.terraform")) {
                        Write-Warning "Terraform not initialized. Running terraform init first..."
                        Invoke-TerraformCommand "init" $workspacePath
                        Write-Host ""
                    }
                    $applySuccess = Invoke-TerraformCommand "apply -auto-approve" $workspacePath
                    
                    # Mark exercise complete if apply succeeded
                    if ($applySuccess) {
                        Write-Host ""
                        if (Mark-ExerciseCompleted $ExerciseId $workspacePath) {
                            Write-Success "Exercise marked as completed!"
                        }
                    }
                }
            }
            5 { 
                # Check if providers are initialized before show
                if (-not (Test-Path "$workspacePath\.terraform")) {
                    Write-Warning "Terraform not initialized. Running terraform init first..."
                    Invoke-TerraformCommand "init" $workspacePath
                    Write-Host ""
                }
                Invoke-TerraformCommand "show" $workspacePath 
            }
            6 {
                if (Test-ExerciseCompletion $ExerciseId $workspacePath) {
                    Write-Success "*** EXERCISE COMPLETED! ***"
                    if ($script:Progress.CompletedExercises -notcontains $ExerciseId) {
                        $script:Progress.CompletedExercises += $ExerciseId
                        $script:Progress.TotalScore += 100
                        Save-Progress
                        Write-Success "Progress saved! Total score: $($script:Progress.TotalScore)"
                        
                        # Show next exercise suggestion
                        $nextExercise = Get-NextExercise $ExerciseId
                        if ($nextExercise) {
                            Write-Info "Ready for the next challenge? Try: $($script:Exercises[$nextExercise].Name)"
                        } else {
                            Write-Success "Congratulations! You have completed all available exercises!"
                        }
                    }
                } else {
                    Show-ExerciseHelp $ExerciseId
                }
            }
            7 {
                # Reset this exercise
                Write-Warning "This will clean up all state and output for this exercise."
                $confirm = Read-Host "Are you sure? (yes/no)"
                if ($confirm -eq "yes") {
                    Push-Location $workspacePath
                    try {
                        Write-Info "Cleaning up Terraform state..."
                        Remove-Item -Path ".terraform", ".terraform.lock.hcl", "terraform.tfstate*", "terraform-lab-output" -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Success "Exercise has been reset!"
                    } finally {
                        Pop-Location
                    }
                } else {
                    Write-Info "Reset cancelled."
                }
            }
            8 { return }
        }
        
        if ($choice -ne 8) {
            Write-Host ""
            Read-Host "Press Enter to continue"
        }
    } while ($true)
}

function Get-NextExercise {
    param([string]$CurrentExercise)
    
    # Get sorted list of exercises
    $sortedExercises = $script:Exercises.Keys | Sort-Object
    $currentIndex = $sortedExercises.IndexOf($CurrentExercise)
    
    if ($currentIndex -ge 0 -and $currentIndex -lt ($sortedExercises.Count - 1)) {
        return $sortedExercises[$currentIndex + 1]
    }
    
    return $null
}

function Show-ExerciseHelp {
    param([string]$ExerciseId)
    
    Write-Host ""
    Write-Host "HELP AND TROUBLESHOOTING" -ForegroundColor Yellow
    Write-Host "======================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Follow this process:" -ForegroundColor White
    Write-Host "  1. Choose GUIDED MODE (option 1) for step-by-step learning" -ForegroundColor Green
    Write-Host "  2. Or manually: Initialize -> Plan -> Apply -> Validate" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "TIPS:" -ForegroundColor Yellow
    Write-Host "  - Read the comments in the .tf files" -ForegroundColor White
    Write-Host "  - Compare Terraform syntax to PowerShell" -ForegroundColor White
    Write-Host "  - Check terraform-lab-output folder after apply" -ForegroundColor White
}

function Save-Progress {
    # Ensure the directory exists
    $progressDir = Split-Path $script:ProgressFile -Parent
    if (-not (Test-Path $progressDir)) {
        New-Item -ItemType Directory -Path $progressDir -Force | Out-Null
    }
    $script:Progress | ConvertTo-Json | Set-Content $script:ProgressFile
}

function Load-Progress {
    if (Test-Path $script:ProgressFile) {
        try {
            $loaded = Get-Content $script:ProgressFile | ConvertFrom-Json
            $script:Progress.UserName = $loaded.UserName
            $script:Progress.CompletedExercises = @($loaded.CompletedExercises)
            $script:Progress.TotalScore = $loaded.TotalScore
        } catch {
            Write-Warning "Could not load progress. Starting fresh."
        }
    }
}

function Reset-LabProgress {
    Write-Warning "This will reset all your progress and start fresh."
    $confirm = Read-Host "Are you sure? (yes/no)"
    
    if ($confirm -eq "yes") {
        # Reset in-memory progress
        $script:Progress = @{
            UserName = ""
            CompletedExercises = @()
            TotalScore = 0
        }
        
        # Delete progress file
        if (Test-Path $script:ProgressFile) {
            Remove-Item $script:ProgressFile -Force
            Write-Success "Progress file deleted: $script:ProgressFile"
        }
        
        Write-Success "Progress has been reset!"
        Write-Info "You can now start fresh with any exercise."
    } else {
        Write-Info "Reset cancelled."
    }
}

function Show-ProgressStats {
    Show-Header "Your Learning Progress"
    
    Write-Host "Student: $($script:Progress.UserName)" -ForegroundColor Green
    Write-Host "Total Score: $($script:Progress.TotalScore)" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Completed Exercises:" -ForegroundColor Cyan
    if ($script:Progress.CompletedExercises.Count -gt 0) {
        $script:Progress.CompletedExercises | ForEach-Object {
            Write-Host "  [DONE] $_" -ForegroundColor Green
        }
    } else {
        Write-Info "No exercises completed yet."
    }
    
    Write-Host ""
    Write-Host "Available Exercises:" -ForegroundColor Cyan
    foreach ($exerciseId in $script:Exercises.Keys | Sort-Object) {
        $exercise = $script:Exercises[$exerciseId]
        $status = if ($script:Progress.CompletedExercises -contains $exerciseId) { "[DONE]" } else { "[TODO]" }
        Write-Host "  $status $($exercise.Name)" -ForegroundColor White
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Show-GeneralHelp {
    Show-Header "Help and Documentation"
    
    Write-Host ""
    Write-Host "TERRAFORM LEARNING LAB - HELP" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This interactive lab teaches Terraform through hands-on exercises," -ForegroundColor White
    Write-Host "designed specifically for PowerShell administrators and developers." -ForegroundColor White
    Write-Host ""
    Write-Host "HOW IT WORKS:" -ForegroundColor Cyan
    Write-Host "  1. Select an exercise from the main menu" -ForegroundColor White
    Write-Host "  2. Choose GUIDED MODE for step-by-step learning" -ForegroundColor White
    Write-Host "  3. Or manually run: init -> plan -> apply -> validate" -ForegroundColor White
    Write-Host "  4. Track your progress as you complete exercises" -ForegroundColor White
    Write-Host ""
    Write-Host "TERRAFORM vs POWERSHELL:" -ForegroundColor Cyan
    Write-Host "  * Terraform is declarative (describe what you want)" -ForegroundColor White
    Write-Host "  * PowerShell is imperative (describe how to do it)" -ForegroundColor White
    Write-Host "  * Both support variables, conditionals, and loops" -ForegroundColor White
    Write-Host ""
    Write-Host "TIPS FOR SUCCESS:" -ForegroundColor Cyan
    Write-Host "  * Start with Hello World even if you know Terraform" -ForegroundColor White
    Write-Host "  * Read the .tf files carefully as they contain examples" -ForegroundColor White
    Write-Host "  * Do not skip the plan step as it shows what will happen" -ForegroundColor White
    Write-Host ""
    
    Read-Host "Press Enter to continue"
}

function Show-MainMenu {
    do {
        $completed = $script:Progress.CompletedExercises.Count
        $total = $script:Exercises.Count
        
        Show-Header "Terraform Learning Lab" "Progress: $completed/$total exercises completed"
        
        if (-not $script:Progress.UserName) {
            Write-Host "Welcome to the Terraform Learning Lab!" -ForegroundColor Green
            $name = Read-Host "What is your name?"
            $script:Progress.UserName = $name
            Save-Progress
            Write-Host ""
        } else {
            Write-Host "Welcome back, $($script:Progress.UserName)!" -ForegroundColor Green
            Write-Host "Score: $($script:Progress.TotalScore)" -ForegroundColor Cyan
            Write-Host ""
        }
        
        # Build dynamic menu from all exercises
        $exerciseOptions = @()
        $exerciseKeys = @()
        foreach ($exerciseId in ($script:Exercises.Keys | Sort-Object)) {
            $exercise = $script:Exercises[$exerciseId]
            $status = if ($script:Progress.CompletedExercises -contains $exerciseId) { "[DONE]" } else { "[TODO]" }
            $difficulty = if ($exercise.Difficulty) { "[$($exercise.Difficulty)]" } else { "" }
            $exerciseOptions += "$status $difficulty $($exercise.Name)"
            $exerciseKeys += $exerciseId
        }
        
        $options = $exerciseOptions + @(
            "View Progress and Statistics",
            "Help and Documentation",
            "Reset Progress (Start Fresh)",
            "Exit Lab"
        )
        
        $choice = Show-Menu $options "What would you like to do?"
        
        if ($choice -lt $exerciseOptions.Count) {
            # Selected an exercise
            Start-Exercise $exerciseKeys[$choice]
        } else {
            # Selected a menu option
            $menuChoice = $choice - $exerciseOptions.Count
            switch ($menuChoice) {
                0 { Show-ProgressStats }
                1 { Show-GeneralHelp }
                2 { Reset-LabProgress }
                3 { 
                    Write-Info "Thank you for using the Terraform Learning Lab!"
                    Write-Host "Keep practicing and happy Terraforming!" -ForegroundColor Green
                    return 
                }
            }
        }
    } while ($true)
}

# Main execution
function Main {
    # Check Terraform installation
    if (-not (Test-TerraformInstallation)) {
        Write-Error "Cannot continue without Terraform. Please install Terraform and try again."
        return
    }
    
    # Load existing progress
    Load-Progress
    
    # Handle command line parameters
    if ($ResetProgress) {
        Reset-LabProgress
        return
    }
    
    if ($ShowStats) {
        Show-ProgressStats
        return
    }
    
    if ($Exercise) {
        if ($script:Exercises.ContainsKey($Exercise)) {
            Start-Exercise $Exercise
        } else {
            Write-Error "Exercise not found: $Exercise"
        }
        return
    }
    
    # Start main interactive session
    Show-MainMenu
}

# Run the lab
Main