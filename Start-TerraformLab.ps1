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
    [switch]$ShowStats
)

$ErrorActionPreference = "Stop"

# Configuration
$script:LabRoot = $PSScriptRoot
$script:TerraformPath = "C:\Tools\Terraform\terraform.exe"
$script:ProgressFile = Join-Path $env:TEMP "terraform-lab-progress.json"

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
        
        # Use Start-Process for interactive commands or direct execution for streaming output
        if ($Command -match "apply" -and $Command -notmatch "auto-approve") {
            # Interactive apply - let user see output and respond
            & $script:TerraformPath $Command.Split(' ')
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

function Test-ExerciseCompletion {
    param([string]$ExerciseId, [string]$WorkspacePath)
    
    # If no workspace path provided, check the exercise directory (legacy)
    if (-not $WorkspacePath) {
        $WorkspacePath = Join-Path $script:LabRoot $ExerciseId
    }
    
    # Basic validation - check if terraform.tfstate exists and has resources
    $statePath = Join-Path $WorkspacePath "terraform.tfstate"
    if (Test-Path $statePath) {
        try {
            $state = Get-Content $statePath | ConvertFrom-Json
            if ($state.resources -and $state.resources.Count -gt 0) {
                Write-Success "Exercise validation passed: $($state.resources.Count) resources found"
                return $true
            }
        } catch {
            Write-Warning "Could not parse state file"
        }
    }
    
    Write-Warning "Exercise not yet complete - no valid Terraform state found"
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
    
    # Create a user workspace for this exercise session
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $workspacePath = Join-Path $env:TEMP "terraform-lab-$($ExerciseId.Replace('/', '-'))-$timestamp"
    
    Write-Info "Creating workspace: $workspacePath"
    New-Item -ItemType Directory -Path $workspacePath -Force | Out-Null
    
    # Copy exercise files to workspace
    Write-Info "Copying exercise files to workspace..."
    Get-ChildItem $exercisePath -File -Filter "*.tf" | ForEach-Object {
        Copy-Item $_.FullName -Destination $workspacePath
    }
    if (Test-Path "$exercisePath\terraform.tfvars") {
        Copy-Item "$exercisePath\terraform.tfvars" -Destination $workspacePath
    }
    
    Show-Header $exercise.Name $exercise.Description
    
    # Check prerequisites
    if (-not (Test-Prerequisites $ExerciseId)) {
        Write-Warning "Please complete prerequisite exercises first."
        Read-Host "Press Enter to continue"
        return
    }
    
    Write-Host "Source Files: $exercisePath" -ForegroundColor Gray
    Write-Host "Workspace: $workspacePath" -ForegroundColor Gray
    Write-Host ""
    Write-Info "Your work will be done in a temporary workspace to keep the lab files clean."
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
                        Invoke-TerraformCommand "apply" $workspacePath
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
                Write-Host "Your workspace files are located at:" -ForegroundColor Cyan
                Write-Host "  $workspacePath" -ForegroundColor White
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
            3 { Invoke-TerraformCommand "plan" $workspacePath }
            4 { 
                Write-Warning "This will create resources. Continue? (y/N)"
                if ((Read-Host) -eq 'y') {
                    Invoke-TerraformCommand "apply -auto-approve" $workspacePath
                }
            }
            5 { Invoke-TerraformCommand "show" $workspacePath }
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
            7 { return }
        }
        
        if ($choice -ne 7) {
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
                2 { 
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