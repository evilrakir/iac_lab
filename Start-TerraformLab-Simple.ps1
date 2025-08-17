#Requires -Version 5.1
<#
.SYNOPSIS
    Simple Interactive Terraform Learning Lab

.DESCRIPTION
    A streamlined interactive experience for learning Terraform with validation and guidance.
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
    "01-basics/01-hello-world" = @{
        Name = "Hello World - Your First Terraform Configuration"
        Description = "Learn basic Terraform syntax and create your first resources"
        Prerequisites = @()
    }
    "01-basics/02-variables" = @{
        Name = "Variables and Data Types"
        Description = "Learn how to use variables and data types in Terraform"
        Prerequisites = @("01-basics/01-hello-world")
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
    param([string]$Command, [string]$WorkingDirectory)
    
    Push-Location $WorkingDirectory
    try {
        Write-Info "Running: terraform $Command"
        Write-Host ""
        
        $result = & $script:TerraformPath $Command.Split(' ')
        
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
    param([string]$ExerciseId)
    
    $exercisePath = Join-Path $script:LabRoot $ExerciseId
    
    # Basic validation - check if terraform.tfstate exists and has resources
    $statePath = Join-Path $exercisePath "terraform.tfstate"
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
    
    Show-Header $exercise.Name $exercise.Description
    
    # Check prerequisites
    if (-not (Test-Prerequisites $ExerciseId)) {
        Write-Warning "Please complete prerequisite exercises first."
        Read-Host "Press Enter to continue"
        return
    }
    
    Write-Host "Exercise Path: $exercisePath" -ForegroundColor Gray
    Write-Host ""
    
    $ready = Read-Host "Ready to start this exercise? (Y/n)"
    if ($ready -eq 'n') { return }
    
    # Interactive exercise session
    do {
        Show-Header "Exercise: $ExerciseId" "Interactive Session"
        
        $options = @(
            "View exercise files",
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
                Write-Info "Exercise files:"
                Get-ChildItem $exercisePath -File | ForEach-Object {
                    Write-Host "  $($_.Name)" -ForegroundColor White
                }
            }
            1 { Invoke-TerraformCommand "init" $exercisePath }
            2 { Invoke-TerraformCommand "plan" $exercisePath }
            3 { 
                Write-Warning "This will create resources. Continue? (y/N)"
                if ((Read-Host) -eq 'y') {
                    Invoke-TerraformCommand "apply -auto-approve" $exercisePath
                }
            }
            4 { Invoke-TerraformCommand "show" $exercisePath }
            5 {
                if (Test-ExerciseCompletion $ExerciseId) {
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
                            Write-Success "Congratulations! You've completed all available exercises!"
                        }
                    }
                } else {
                    Show-ExerciseHelp $ExerciseId
                }
            }
            6 { return }
        }
        
        if ($choice -ne 6) {
            Write-Host ""
            Read-Host "Press Enter to continue"
        }
    } while ($true)
}

function Get-NextExercise {
    param([string]$CurrentExercise)
    
    switch ($CurrentExercise) {
        "01-basics/01-hello-world" { return "01-basics/02-variables" }
        default { return $null }
    }
}

function Show-ExerciseHelp {
    param([string]$ExerciseId)
    
    Write-Host ""
    Write-Host "HELP & TROUBLESHOOTING" -ForegroundColor Yellow
    Write-Host "======================" -ForegroundColor Yellow
    
    switch ($ExerciseId) {
        "01-basics/01-hello-world" {
            Write-Host @"

GETTING STARTED:
1. Initialize Terraform: Choose option 2 (terraform init)
2. Preview changes: Choose option 3 (terraform plan)
3. Apply configuration: Choose option 4 (terraform apply)
4. Validate completion: Choose option 6

TROUBLESHOOTING:
• If 'terraform init' fails: Check internet connection
• If 'terraform plan' fails: Review .tf files for syntax errors
• If 'terraform apply' fails: Check file permissions

LEARNING TIPS:
• Compare Terraform syntax to PowerShell - notice similarities!
• Examine the created files in terraform-lab-output/
• Run the created PowerShell script to see concept comparisons

"@ -ForegroundColor White
        }
        "01-basics/02-variables" {
            Write-Host @"

GETTING STARTED:
1. Look at variables.tf to see variable definitions
2. Notice how variables are used in main.tf
3. Run through init -> plan -> apply sequence
4. Check the outputs to see variable usage

TROUBLESHOOTING:
• Variable errors: Check data types and validation rules
• File path issues: Variables control file locations
• Missing outputs: Ensure all resources created successfully

LEARNING TIPS:
• Variables in Terraform = Parameters in PowerShell
• Locals in Terraform = Variables in PowerShell
• Try changing default values and re-running

"@ -ForegroundColor White
        }
        default {
            Write-Host "General help available. Follow the step-by-step process:" -ForegroundColor White
            Write-Host "1. Initialize -> 2. Plan -> 3. Apply -> 4. Validate" -ForegroundColor Cyan
        }
    }
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
    
    Write-Host @"
TERRAFORM LEARNING LAB - HELP

This interactive lab teaches Terraform through hands-on exercises,
designed specifically for PowerShell administrators and developers.

HOW IT WORKS:
1. Select an exercise from the main menu
2. Follow the guided workflow: init -> plan -> apply -> validate
3. Get help and hints when stuck
4. Track your progress as you complete exercises

EXERCISE WORKFLOW:
• View Files: See the Terraform configuration files
• Initialize: Run 'terraform init' to set up the working directory  
• Plan: Run 'terraform plan' to preview changes
• Apply: Run 'terraform apply' to create resources
• Show: Run 'terraform show' to inspect current state
• Validate: Check exercise completion

TERRAFORM vs POWERSHELL:
• Terraform is declarative (describe what you want)
• PowerShell is imperative (describe how to do it)
• Both support variables, conditionals, and loops
• Both can be version controlled and automated

GETTING HELP:
• Exercise-specific help is available in the validation step
• Each exercise includes troubleshooting tips
• Compare concepts to familiar PowerShell patterns

TIPS FOR SUCCESS:
• Start with Hello World even if you know Terraform
• Read the .tf files carefully - they contain examples
• Don't skip the plan step - it shows what will happen
• Experiment! You can always destroy and start over

Happy learning!

"@ -ForegroundColor White
    
    Read-Host "Press Enter to continue"
}

function Show-MainMenu {
    do {
        $completed = $script:Progress.CompletedExercises.Count
        $total = $script:Exercises.Count
        
        Show-Header "Terraform Learning Lab" "Progress: $completed/$total exercises completed"
        
        if (-not $script:Progress.UserName) {
            Write-Host "Welcome to the Terraform Learning Lab!" -ForegroundColor Green
            $name = Read-Host "What's your name?"
            $script:Progress.UserName = $name
            Save-Progress
            Write-Host ""
        } else {
            Write-Host "Welcome back, $($script:Progress.UserName)!" -ForegroundColor Green
            Write-Host "Score: $($script:Progress.TotalScore)" -ForegroundColor Cyan
            Write-Host ""
        }
        
        $options = @(
            "Start Exercise: Hello World (Basics)",
            "Start Exercise: Variables and Data Types", 
            "View Progress and Statistics",
            "Help and Documentation",
            "Exit Lab"
        )
        
        $choice = Show-Menu $options "What would you like to do?"
        
        switch ($choice) {
            0 { Start-Exercise "01-basics/01-hello-world" }
            1 { Start-Exercise "01-basics/02-variables" }
            2 { Show-ProgressStats }
            3 { Show-GeneralHelp }
            4 { 
                Write-Info "Thank you for using the Terraform Learning Lab!"
                Write-Host "Keep practicing and happy Terraforming!" -ForegroundColor Green
                return 
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