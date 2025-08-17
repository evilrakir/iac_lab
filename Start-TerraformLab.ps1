#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive Terraform Learning Lab - Your guided journey to Terraform mastery
.DESCRIPTION
    An interactive, guided learning experience for Terraform with real-time validation,
    hints, progress tracking, and hands-on exercises.
.EXAMPLE
    .\Start-TerraformLab.ps1
.EXAMPLE
    .\Start-TerraformLab.ps1 -Resume
.EXAMPLE
    .\Start-TerraformLab.ps1 -Exercise "07-containers/01-docker-provider"
#>
[CmdletBinding()]
param(
    [switch]$Resume,
    [string]$Exercise,
    [switch]$ResetProgress,
    [switch]$ShowStats
)

$ErrorActionPreference = "Stop"
$script:LabVersion = "2.0.0"
$script:LabRoot = $PSScriptRoot
$script:ProgressFile = Join-Path $env:LOCALAPPDATA "TerraformLab\progress.json"
$script:ConfigFile = Join-Path $env:LOCALAPPDATA "TerraformLab\config.json"

# Import lab modules
$modulePath = Join-Path $PSScriptRoot "scripts\modules"
if (Test-Path $modulePath) {
    Get-ChildItem -Path $modulePath -Filter "*.psm1" | ForEach-Object {
        Import-Module $_.FullName -Force
    }
}

# Console UI Helper Functions
function Write-LabHeader {
    param([string]$Text, [string]$SubText = "")
    
    Clear-Host
    $width = [Console]::WindowWidth
    $line = "=" * $width
    
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
    $padding = [math]::Max(0, ($width - $Text.Length) / 2)
    Write-Host (" " * $padding) -NoNewline
    Write-Host $Text -ForegroundColor Yellow
    if ($SubText) {
        Write-Host ""
        $subPadding = [math]::Max(0, ($width - $SubText.Length) / 2)
        Write-Host (" " * $subPadding) -NoNewline
        Write-Host $SubText -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
}

function Write-MenuItem {
    param(
        [string]$Number,
        [string]$Text,
        [string]$Status = "",
        [switch]$Highlight
    )
    
    $color = if ($Highlight) { "Yellow" } else { "White" }
    $statusColor = switch ($Status) {
        "Completed" { "Green" }
        "In Progress" { "Yellow" }
        "Locked" { "DarkGray" }
        "New" { "Cyan" }
        default { "Gray" }
    }
    
    Write-Host "  [$Number] " -ForegroundColor $color -NoNewline
    Write-Host $Text -ForegroundColor $color -NoNewline
    if ($Status) {
        Write-Host " [$Status]" -ForegroundColor $statusColor
    } else {
        Write-Host ""
    }
}

function Show-TypewriterText {
    param(
        [string]$Text,
        [int]$DelayMs = 20,
        [ConsoleColor]$Color = "White"
    )
    
    $Text.ToCharArray() | ForEach-Object {
        Write-Host $_ -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $DelayMs
    }
    Write-Host ""
}

function Show-ProgressBar {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Activity = "Progress"
    )
    
    $percent = [math]::Round(($Current / $Total) * 100)
    $barLength = 50
    $filled = [math]::Round(($percent / 100) * $barLength)
    $empty = $barLength - $filled
    
    Write-Host "`r  $Activity`: [" -NoNewline
    Write-Host ("█" * $filled) -ForegroundColor Green -NoNewline
    Write-Host ("░" * $empty) -ForegroundColor DarkGray -NoNewline
    Write-Host "] $percent%" -NoNewline
}

# Progress Management
class LabProgress {
    [hashtable]$Exercises = @{}
    [string]$CurrentExercise
    [datetime]$StartedAt
    [datetime]$LastSessionAt
    [int]$TotalTimeMinutes = 0
    [hashtable]$Achievements = @{}
    [string]$UserName
    [string]$PreferredEditor = "code"
    
    Save([string]$Path) {
        $dir = Split-Path $Path -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        $this | ConvertTo-Json -Depth 10 | Set-Content -Path $Path
    }
    
    static [LabProgress] Load([string]$Path) {
        if (Test-Path $Path) {
            $json = Get-Content -Path $Path -Raw | ConvertFrom-Json
            $progress = [LabProgress]::new()
            $json.PSObject.Properties | ForEach-Object {
                $progress.$($_.Name) = $_.Value
            }
            return $progress
        }
        return [LabProgress]::new()
    }
}

# Load or Initialize Progress
$script:Progress = if ($ResetProgress) {
    [LabProgress]::new()
} else {
    [LabProgress]::Load($script:ProgressFile)
}

# Exercise Definition
class Exercise {
    [string]$Id
    [string]$Name
    [string]$Description
    [string]$Path
    [string]$Category
    [string]$Difficulty
    [string[]]$Prerequisites = @()
    [string[]]$Objectives = @()
    [hashtable]$ValidationSteps = @{}
    [string[]]$Hints = @()
    [string[]]$CommonErrors = @()
    [int]$EstimatedMinutes = 15
    [bool]$IsModern = $true
    [bool]$IsOptional = $false
}

# Exercise Catalog
$script:Exercises = @{
    "01-basics/01-hello-world" = @{
        Name = "Hello World - Your First Terraform Configuration"
        Description = "Learn the basics of Terraform with a simple local file resource"
        Category = "Basics"
        Difficulty = "Beginner"
        EstimatedMinutes = 10
        Objectives = @(
            "Understand Terraform configuration structure"
            "Learn about providers and resources"
            "Run terraform init, plan, and apply"
            "Understand state files"
        )
        ValidationSteps = @{
            "terraform_installed" = { Get-Command terraform -ErrorAction SilentlyContinue }
            "init_completed" = { Test-Path ".terraform" }
            "plan_successful" = { terraform plan -out=tfplan 2>$null; $? }
            "apply_successful" = { Test-Path "terraform.tfstate" }
            "output_created" = { Test-Path "terraform-lab-output" }
        }
        Hints = @(
            "Run 'terraform init' first to download the provider"
            "Use 'terraform plan' to preview changes before applying"
            "Check the terraform.tfstate file to understand state management"
        )
    }
    
    "01-basics/02-variables" = @{
        Name = "Variables - Input and Local Values"
        Description = "Master Terraform variables, locals, and validation"
        Category = "Basics"
        Difficulty = "Beginner"
        EstimatedMinutes = 20
        Prerequisites = @("01-basics/01-hello-world")
        Objectives = @(
            "Define and use input variables"
            "Understand variable types and validation"
            "Use local values for computed values"
            "Override variables with tfvars files"
        )
    }
    
    "07-containers/01-docker-provider" = @{
        Name = "Docker Provider - Container Management"
        Description = "Use Terraform to manage Docker containers"
        Category = "Containers"
        Difficulty = "Intermediate"
        EstimatedMinutes = 30
        IsModern = $true
        Prerequisites = @("01-basics/02-variables")
        Objectives = @(
            "Configure Docker provider for Windows"
            "Deploy containers with Terraform"
            "Manage container networks and volumes"
            "Implement health checks"
        )
        ValidationSteps = @{
            "docker_running" = { docker version 2>$null; $? }
            "provider_configured" = { Test-Path "main.tf" -and (Select-String -Path "main.tf" -Pattern "provider.*docker") }
            "container_running" = { docker ps --filter "name=terraform-" --format "table {{.Names}}" }
        }
        Hints = @(
            "Ensure Docker Desktop is running first"
            "Windows uses npipe:////./pipe/docker_engine for Docker host"
            "Use 'docker ps' to verify containers are running"
        )
    }
    
    "07-containers/02-kubernetes-basics" = @{
        Name = "Kubernetes - Managing K8s Resources"
        Description = "Deploy applications to Kubernetes with Terraform"
        Category = "Containers"
        Difficulty = "Intermediate"
        EstimatedMinutes = 45
        IsModern = $true
        Prerequisites = @("07-containers/01-docker-provider")
        Objectives = @(
            "Configure Kubernetes provider"
            "Create namespaces, deployments, and services"
            "Manage ConfigMaps and Secrets"
            "Implement autoscaling and ingress"
        )
    }
    
    "08-integrations/01-terraform-ansible" = @{
        Name = "Terraform + Ansible Integration"
        Description = "Combine infrastructure provisioning with configuration management"
        Category = "Integrations"
        Difficulty = "Advanced"
        EstimatedMinutes = 60
        IsModern = $true
        Prerequisites = @("01-basics/02-variables")
        Objectives = @(
            "Generate Ansible inventory from Terraform"
            "Use local-exec provisioners"
            "Integrate with WSL2 for Ansible on Windows"
            "Create dynamic playbooks"
        )
    }
    
    "09-legacy-optional/01-vagrant" = @{
        Name = "[LEGACY] Vagrant Provider"
        Description = "Work with Vagrant boxes (optional - containers recommended)"
        Category = "Legacy"
        Difficulty = "Intermediate"
        EstimatedMinutes = 30
        IsOptional = $true
        Objectives = @(
            "Understand Vagrant's role (historical context)"
            "Learn migration path to containers"
            "Compare with modern approaches"
        )
    }
}

# Interactive Exercise Runner
function Start-Exercise {
    param([string]$ExerciseId)
    
    $exercise = $script:Exercises[$ExerciseId]
    if (-not $exercise) {
        Write-Host "Exercise not found: $ExerciseId" -ForegroundColor Red
        return
    }
    
    $exercisePath = Join-Path $script:LabRoot $ExerciseId
    if (-not (Test-Path $exercisePath)) {
        Write-Host "Exercise path not found: $exercisePath" -ForegroundColor Red
        return
    }
    
    # Update progress
    $script:Progress.CurrentExercise = $ExerciseId
    if (-not $script:Progress.Exercises.ContainsKey($ExerciseId)) {
        $script:Progress.Exercises[$ExerciseId] = @{
            StartedAt = Get-Date
            Status = "In Progress"
            CompletedSteps = @()
        }
    }
    $script:Progress.Save($script:ProgressFile)
    
    # Show exercise introduction
    Write-LabHeader $exercise.Name $exercise.Description
    
    Write-Host "📚 Learning Objectives:" -ForegroundColor Cyan
    $exercise.Objectives | ForEach-Object {
        Write-Host "   ✓ $_" -ForegroundColor White
    }
    Write-Host ""
    
    Write-Host "⏱️  Estimated Time: $($exercise.EstimatedMinutes) minutes" -ForegroundColor Yellow
    Write-Host "📁 Exercise Path: $exercisePath" -ForegroundColor Gray
    Write-Host ""
    
    # Check prerequisites
    if ($exercise.Prerequisites -and $exercise.Prerequisites.Count -gt 0) {
        Write-Host "📋 Checking Prerequisites..." -ForegroundColor Cyan
        $allMet = $true
        foreach ($prereq in $exercise.Prerequisites) {
            if ($script:Progress.Exercises[$prereq].Status -eq "Completed") {
                Write-Host "   [OK] $prereq" -ForegroundColor Green
            } else {
                Write-Host "   [X] $prereq (not completed)" -ForegroundColor Red
                $allMet = $false
            }
        }
        
        if (-not $allMet) {
            Write-Host "`n⚠️  Please complete prerequisites first!" -ForegroundColor Yellow
            Read-Host "Press Enter to return to menu"
            return
        }
    }
    
    Write-Host "`n" -NoNewline
    $ready = Read-Host "Ready to start? (Y/n)"
    if ($ready -eq 'n') { return }
    
    # Change to exercise directory
    Push-Location $exercisePath
    
    try {
        # Show exercise files
        Write-Host "`n📂 Exercise Files:" -ForegroundColor Cyan
        Get-ChildItem -Path . -File | ForEach-Object {
            $icon = switch ($_.Extension) {
                ".tf" { "📄" }
                ".md" { "📖" }
                ".ps1" { "⚡" }
                ".yml" { "📋" }
                ".yaml" { "📋" }
                default { "📎" }
            }
            Write-Host "   $icon $($_.Name)" -ForegroundColor White
        }
        
        # Interactive exercise loop
        $exerciseComplete = $false
        while (-not $exerciseComplete) {
            Write-Host "`n" -NoNewline
            Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
            Write-Host "║         EXERCISE MENU                  ║" -ForegroundColor Cyan
            Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
            
            Write-MenuItem "1" "View exercise instructions"
            Write-MenuItem "2" "Open in editor ($($script:Progress.PreferredEditor))"
            Write-MenuItem "3" "Run 'terraform init'"
            Write-MenuItem "4" "Run 'terraform plan'"
            Write-MenuItem "5" "Run 'terraform apply'"
            Write-MenuItem "6" "Validate exercise completion"
            Write-MenuItem "7" "Get a hint"
            Write-MenuItem "8" "Show common errors & solutions"
            Write-MenuItem "9" "Run custom command"
            Write-MenuItem "0" "Exit exercise"
            
            Write-Host ""
            $choice = Read-Host "Select option"
            
            switch ($choice) {
                "1" { Show-ExerciseInstructions $ExerciseId }
                "2" { Start-Process $script:Progress.PreferredEditor -ArgumentList "." }
                "3" { 
                    Write-Host "`n🚀 Running terraform init..." -ForegroundColor Cyan
                    terraform init
                    if ($?) {
                        Write-Host "✅ Terraform initialized successfully!" -ForegroundColor Green
                    }
                }
                "4" {
                    Write-Host "`n🔍 Running terraform plan..." -ForegroundColor Cyan
                    terraform plan
                    if ($?) {
                        Write-Host "✅ Plan completed successfully!" -ForegroundColor Green
                    }
                }
                "5" {
                    Write-Host "`n🚀 Running terraform apply..." -ForegroundColor Cyan
                    terraform apply
                    if ($?) {
                        Write-Host "✅ Apply completed successfully!" -ForegroundColor Green
                    }
                }
                "6" { 
                    $valid = Test-ExerciseCompletion $ExerciseId
                    if ($valid) {
                        Complete-Exercise $ExerciseId
                        $exerciseComplete = $true
                    }
                }
                "7" { Show-Hint $ExerciseId }
                "8" { Show-CommonErrors $ExerciseId }
                "9" {
                    $cmd = Read-Host "Enter command"
                    if ($cmd) {
                        Invoke-Expression $cmd
                    }
                }
                "0" { $exerciseComplete = $true }
                default { Write-Host "Invalid option" -ForegroundColor Red }
            }
            
            if (-not $exerciseComplete) {
                Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
                Read-Host
            }
        }
    }
    finally {
        Pop-Location
    }
}

function Show-ExerciseInstructions {
    param([string]$ExerciseId)
    
    $readmePath = Join-Path $script:LabRoot $ExerciseId "README.md"
    if (Test-Path $readmePath) {
        Get-Content $readmePath | Out-Host -Paging
    } else {
        $instructionsPath = Join-Path $script:LabRoot $ExerciseId "instructions.md"
        if (Test-Path $instructionsPath) {
            Get-Content $instructionsPath | Out-Host -Paging
        } else {
            Write-Host "No instructions file found" -ForegroundColor Yellow
            Write-Host "Check the .tf files for inline comments" -ForegroundColor Gray
        }
    }
}

function Test-ExerciseCompletion {
    param([string]$ExerciseId)
    
    Write-Host "`n🔍 Validating Exercise Completion..." -ForegroundColor Cyan
    
    $exercise = $script:Exercises[$ExerciseId]
    if (-not $exercise.ValidationSteps) {
        Write-Host "No validation steps defined for this exercise" -ForegroundColor Yellow
        $manual = Read-Host "Mark as complete manually? (y/N)"
        return ($manual -eq 'y')
    }
    
    $allPassed = $true
    foreach ($step in $exercise.ValidationSteps.GetEnumerator()) {
        Write-Host "  Checking: $($step.Key)..." -NoNewline
        
        $result = & $step.Value
        if ($result) {
            Write-Host " ✅" -ForegroundColor Green
        } else {
            Write-Host " ❌" -ForegroundColor Red
            $allPassed = $false
        }
    }
    
    if ($allPassed) {
        Write-Host "`n🎉 All validation steps passed!" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  Some validation steps failed" -ForegroundColor Yellow
        Write-Host "Review the requirements and try again" -ForegroundColor Gray
    }
    
    return $allPassed
}

function Complete-Exercise {
    param([string]$ExerciseId)
    
    $script:Progress.Exercises[$ExerciseId].Status = "Completed"
    $script:Progress.Exercises[$ExerciseId].CompletedAt = Get-Date
    $script:Progress.Save($script:ProgressFile)
    
    Write-Host "`n" -NoNewline
    Write-Host "🎊🎊🎊 EXERCISE COMPLETED! 🎊🎊🎊" -ForegroundColor Green
    Write-Host ""
    
    # Show achievement
    $exercise = $script:Exercises[$ExerciseId]
    $achievement = "Completed: $($exercise.Name)"
    
    Show-TypewriterText "Achievement Unlocked: $achievement" -Color Yellow
    
    # Update statistics
    $completed = ($script:Progress.Exercises.Values | Where-Object { $_.Status -eq "Completed" }).Count
    $total = $script:Exercises.Count
    
    Write-Host "`nProgress: $completed/$total exercises completed" -ForegroundColor Cyan
    Show-ProgressBar -Current $completed -Total $total -Activity "Overall Progress"
    Write-Host "`n"
    
    Read-Host "Press Enter to continue"
}

function Show-Hint {
    param([string]$ExerciseId)
    
    $exercise = $script:Exercises[$ExerciseId]
    if (-not $exercise.Hints -or $exercise.Hints.Count -eq 0) {
        Write-Host "No hints available for this exercise" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n💡 HINTS:" -ForegroundColor Yellow
    $hintNum = Get-Random -Minimum 0 -Maximum $exercise.Hints.Count
    Write-Host "   $($exercise.Hints[$hintNum])" -ForegroundColor White
    Write-Host ""
    Write-Host "   (Hints are shown randomly, try again for another hint)" -ForegroundColor Gray
}

function Show-CommonErrors {
    param([string]$ExerciseId)
    
    Write-Host "`n[!] COMMON ERRORS AND SOLUTIONS:" -ForegroundColor Yellow
    Write-Host ""
    
    $commonErrors = @{
        "terraform init" = @{
            "Error: Required plugins are not installed" = "Run 'terraform init' to download providers"
            "Error: Backend initialization required" = "Check backend configuration in terraform block"
        }
        "terraform plan" = @{
            "Error: Reference to undeclared resource" = "Check resource names and ensure they're defined"
            "Error: Unsupported argument" = "Check provider documentation for valid arguments"
        }
        "terraform apply" = @{
            "Error: Resource already exists" = "Import existing resource or use different name"
            "Error: Insufficient permissions" = "Check cloud provider credentials and permissions"
        }
        "docker" = @{
            "Cannot connect to Docker daemon" = "Ensure Docker Desktop is running"
            "Permission denied" = "Run PowerShell as Administrator or add user to docker group"
        }
        "kubernetes" = @{
            "Unable to connect to the server" = "Check kubectl context and cluster status"
            "No resources found" = "Ensure you're in the correct namespace"
        }
    }
    
    foreach ($category in $commonErrors.GetEnumerator()) {
        Write-Host "  $($category.Key):" -ForegroundColor Cyan
        foreach ($error in $category.Value.GetEnumerator()) {
            Write-Host "    [X] $($error.Key)" -ForegroundColor Red
            Write-Host "    [OK] $($error.Value)" -ForegroundColor Green
            Write-Host ""
        }
    }
}

# Main Menu
function Show-MainMenu {
    Write-LabHeader "🚀 MODERN INFRASTRUCTURE AS CODE FOR WINDOWS ADMINS" "Terraform Mastery Course v$script:LabVersion"
    
    # Show user info
    if ($script:Progress.UserName) {
        Write-Host "Welcome back, $($script:Progress.UserName)! " -ForegroundColor Green -NoNewline
        
        $completed = ($script:Progress.Exercises.Values | Where-Object { $_.Status -eq "Completed" }).Count
        $total = $script:Exercises.Count
        Write-Host "($completed/$total completed)" -ForegroundColor Cyan
    } else {
        Write-Host "Welcome to the Terraform Learning Lab!" -ForegroundColor Green
        $name = Read-Host "What's your name?"
        $script:Progress.UserName = $name
        $script:Progress.StartedAt = Get-Date
        $script:Progress.Save($script:ProgressFile)
    }
    
    Write-Host ""
    Write-Host "📚 LEARNING PATHS" -ForegroundColor Yellow
    Write-Host "─────────────────" -ForegroundColor Gray
    
    # Group exercises by category
    $categories = $script:Exercises.GetEnumerator() | Group-Object { $_.Value.Category }
    
    $menuIndex = 1
    $menuMap = @{}
    
    foreach ($category in $categories) {
        Write-Host "`n  $($category.Name):" -ForegroundColor Cyan
        
        foreach ($exercise in $category.Group) {
            $status = if ($script:Progress.Exercises[$exercise.Key].Status) {
                $script:Progress.Exercises[$exercise.Key].Status
            } else {
                "New"
            }
            
            $prefix = if ($exercise.Value.IsOptional) { "[Optional] " } else { "" }
            $modern = if ($exercise.Value.IsModern) { "🆕 " } else { "" }
            
            Write-MenuItem $menuIndex "$modern$prefix$($exercise.Value.Name)" $status
            $menuMap[$menuIndex.ToString()] = $exercise.Key
            $menuIndex++
        }
    }
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-MenuItem "E" "Environment Check"
    Write-MenuItem "P" "Show Progress & Stats"
    Write-MenuItem "S" "Settings"
    Write-MenuItem "H" "Help & Documentation"
    Write-MenuItem "R" "Reset Progress"
    Write-MenuItem "Q" "Quit"
    
    Write-Host ""
    $choice = Read-Host "Select exercise number or option"
    
    switch ($choice.ToUpper()) {
        "E" { 
            & (Join-Path $script:LabRoot "scripts\Check-Environment.ps1")
            Read-Host "`nPress Enter to continue"
        }
        "P" { Show-Progress }
        "S" { Show-Settings }
        "H" { Show-Help }
        "R" { 
            $confirm = Read-Host "Are you sure you want to reset all progress? (yes/no)"
            if ($confirm -eq "yes") {
                $script:Progress = [LabProgress]::new()
                $script:Progress.Save($script:ProgressFile)
                Write-Host "Progress reset!" -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        }
        "Q" { return $false }
        default {
            if ($menuMap.ContainsKey($choice)) {
                Start-Exercise $menuMap[$choice]
            } else {
                Write-Host "Invalid option" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
    
    return $true
}

function Show-Progress {
    Write-LabHeader "📊 YOUR PROGRESS"
    
    $completed = $script:Progress.Exercises.Values | Where-Object { $_.Status -eq "Completed" }
    $inProgress = $script:Progress.Exercises.Values | Where-Object { $_.Status -eq "In Progress" }
    
    Write-Host "Overall Statistics:" -ForegroundColor Cyan
    Write-Host "  Exercises Completed: $($completed.Count)/$($script:Exercises.Count)" -ForegroundColor White
    Write-Host "  Exercises In Progress: $($inProgress.Count)" -ForegroundColor White
    
    if ($script:Progress.StartedAt) {
        $duration = (Get-Date) - [datetime]$script:Progress.StartedAt
        Write-Host "  Learning Since: $($script:Progress.StartedAt.ToString('yyyy-MM-dd'))" -ForegroundColor White
        Write-Host "  Total Days: $([math]::Round($duration.TotalDays))" -ForegroundColor White
    }
    
    # Show completion by category
    Write-Host "`nProgress by Category:" -ForegroundColor Cyan
    $categories = $script:Exercises.GetEnumerator() | Group-Object { $_.Value.Category }
    
    foreach ($category in $categories) {
        $catCompleted = 0
        foreach ($exercise in $category.Group) {
            if ($script:Progress.Exercises[$exercise.Key].Status -eq "Completed") {
                $catCompleted++
            }
        }
        
        Write-Host "  $($category.Name): " -NoNewline
        Show-ProgressBar -Current $catCompleted -Total $category.Count -Activity ""
        Write-Host ""
    }
    
    # Achievements
    if ($completed.Count -gt 0) {
        Write-Host "`n🏆 Achievements:" -ForegroundColor Yellow
        
        if ($completed.Count -ge 1) {
            Write-Host "  ⭐ First Steps - Completed your first exercise" -ForegroundColor Green
        }
        if ($completed.Count -ge 5) {
            Write-Host "  ⭐⭐ Making Progress - Completed 5 exercises" -ForegroundColor Green
        }
        if ($completed.Count -ge 10) {
            Write-Host "  ⭐⭐⭐ Terraform Practitioner - Completed 10 exercises" -ForegroundColor Green
        }
        if ($completed.Count -eq $script:Exercises.Count) {
            Write-Host "  🌟🌟🌟 TERRAFORM MASTER - Completed ALL exercises!" -ForegroundColor Gold
        }
    }
    
    Read-Host "`nPress Enter to continue"
}

function Show-Settings {
    Write-LabHeader "⚙️ SETTINGS"
    
    Write-Host "Current Settings:" -ForegroundColor Cyan
    Write-Host "  Preferred Editor: $($script:Progress.PreferredEditor)" -ForegroundColor White
    Write-Host "  Progress File: $script:ProgressFile" -ForegroundColor White
    Write-Host ""
    
    Write-MenuItem "1" "Change preferred editor"
    Write-MenuItem "2" "Export progress to file"
    Write-MenuItem "3" "Import progress from file"
    Write-MenuItem "0" "Back to main menu"
    
    Write-Host ""
    $choice = Read-Host "Select option"
    
    switch ($choice) {
        "1" {
            Write-Host "Available editors: code, notepad++, notepad, vim" -ForegroundColor Gray
            $editor = Read-Host "Enter preferred editor command"
            if ($editor) {
                $script:Progress.PreferredEditor = $editor
                $script:Progress.Save($script:ProgressFile)
                Write-Host "Editor updated!" -ForegroundColor Green
            }
        }
        "2" {
            $exportPath = Read-Host "Enter export path (e.g., C:\backup\progress.json)"
            if ($exportPath) {
                Copy-Item $script:ProgressFile $exportPath
                Write-Host "Progress exported to $exportPath" -ForegroundColor Green
            }
        }
        "3" {
            $importPath = Read-Host "Enter import path"
            if ($importPath -and (Test-Path $importPath)) {
                Copy-Item $importPath $script:ProgressFile
                $script:Progress = [LabProgress]::Load($script:ProgressFile)
                Write-Host "Progress imported!" -ForegroundColor Green
            }
        }
    }
    
    if ($choice -ne "0") {
        Read-Host "Press Enter to continue"
        Show-Settings
    }
}

function Show-Help {
    Write-LabHeader "📚 HELP & DOCUMENTATION"
    
    $helpText = @"
TERRAFORM LEARNING LAB - HELP

This interactive lab guides you through learning Terraform from basics to advanced topics.

HOW IT WORKS:
1. Select an exercise from the main menu
2. Follow the interactive prompts
3. Write and test Terraform configurations
4. Validate your work
5. Get hints if you're stuck
6. Complete exercises to track progress

EXERCISE STRUCTURE:
- Each exercise has clear objectives
- Prerequisites ensure proper learning order
- Validation checks your understanding
- Hints help when you're stuck

TIPS FOR SUCCESS:
- Start with the basics even if you have experience
- Read the .tf files carefully - they contain inline documentation
- Use 'terraform plan' before 'apply' to understand changes
- Don't skip exercises - they build on each other
- Experiment and break things - that's how you learn!

KEYBOARD SHORTCUTS (in exercise):
- Use arrow keys to navigate menus
- Tab completion works in PowerShell
- Ctrl+C to cancel operations

GETTING HELP:
- Each exercise has hints (option 7)
- Common errors are documented (option 8)
- Check .\scripts\Check-Environment.ps1 for tool issues
- README files contain detailed information

MODERN vs LEGACY:
- 🆕 marks modern, recommended technologies
- 📌 marks legacy/optional content
- Focus on modern practices but understand legacy for real-world scenarios

For more help, see the README.md file in the lab root directory.
"@
    
    Write-Host $helpText -ForegroundColor White
    Read-Host "`nPress Enter to continue"
}

# Welcome Screen
function Show-Welcome {
    Clear-Host
    $art = @"
    
     ╔══════════════════════════════════════════════════════════════╗
     ║                                                              ║
     ║   🌟  MODERN INFRASTRUCTURE AS CODE  🌟                     ║
     ║            FOR WINDOWS ADMINS                               ║
     ║                                                              ║
     ║     ████████╗███████╗██████╗ ██████╗  █████╗               ║
     ║     ╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗              ║
     ║        ██║   █████╗  ██████╔╝██████╔╝███████║              ║
     ║        ██║   ██╔══╝  ██╔══██╗██╔══██╗██╔══██║              ║
     ║        ██║   ███████╗██║  ██║██║  ██║██║  ██║              ║
     ║        ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝              ║
     ║                                                              ║
     ║         F O R M   M A S T E R Y   C O U R S E              ║
     ║                                                              ║
     ║      🔧 PowerShell Native  ☁️ Cloud Ready  🐋 Container First ║
     ║                                                              ║
     ╚══════════════════════════════════════════════════════════════╝
    
"@
    
    Write-Host $art -ForegroundColor Cyan
    Write-Host "           Windows Admin Edition v$script:LabVersion | Terraform + PowerShell + DevOps" -ForegroundColor Yellow
    Write-Host ""
    
    Show-TypewriterText "    Bridging the gap between Windows administration and modern cloud infrastructure!" -Color White -DelayMs 30
    Write-Host ""
    Start-Sleep -Seconds 1
    
    # Quick environment check
    Write-Host "    Checking environment..." -ForegroundColor Gray
    $terraform = Get-Command terraform -ErrorAction SilentlyContinue
    $docker = docker version 2>$null
    
    if ($terraform) {
        Write-Host "    ✅ Terraform detected" -ForegroundColor Green
    } else {
        Write-Host "    ⚠️  Terraform not found (run .\scripts\Install-LabTools.ps1)" -ForegroundColor Yellow
    }
    
    if ($docker) {
        Write-Host "    ✅ Docker detected" -ForegroundColor Green
    } else {
        Write-Host "    ⚠️  Docker not running (optional for container exercises)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "    Press Enter to begin your learning journey..." -ForegroundColor Cyan
    Read-Host
}

# Main Execution
function Start-Lab {
    # Show welcome on first run
    if (-not $script:Progress.UserName) {
        Show-Welcome
    }
    
    # Main loop
    $continue = $true
    while ($continue) {
        $continue = Show-MainMenu
    }
    
    # Save progress on exit
    $script:Progress.LastSessionAt = Get-Date
    $script:Progress.Save($script:ProgressFile)
    
    Clear-Host
    Write-Host ""
    Write-Host "Thanks for learning with Terraform Lab!" -ForegroundColor Green
    Write-Host "Your progress has been saved." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Continue your journey anytime with: .\Start-TerraformLab.ps1" -ForegroundColor Cyan
    Write-Host ""
}

# Handle parameters
if ($ShowStats) {
    $progress = [LabProgress]::Load($script:ProgressFile)
    $completed = ($progress.Exercises.Values | Where-Object { $_.Status -eq "Completed" }).Count
    
    Write-Host "Terraform Lab Statistics:" -ForegroundColor Cyan
    Write-Host "  User: $($progress.UserName)" -ForegroundColor White
    Write-Host "  Completed: $completed/$($script:Exercises.Count)" -ForegroundColor White
    Write-Host "  Started: $($progress.StartedAt)" -ForegroundColor White
    
    exit 0
}

if ($Exercise) {
    if ($script:Exercises.ContainsKey($Exercise)) {
        Start-Exercise $Exercise
    } else {
        Write-Host "Exercise not found: $Exercise" -ForegroundColor Red
        Write-Host "Available exercises:" -ForegroundColor Yellow
        $script:Exercises.Keys | ForEach-Object { Write-Host "  $_" }
    }
    exit 0
}

# Start the lab
Start-Lab