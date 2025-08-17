#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive Terraform Learning Lab - Your guided journey to Terraform mastery

.DESCRIPTION
    An interactive, guided learning experience for Terraform with real-time validation,
    hints, progress tracking, and hands-on exercises. Designed specifically for 
    PowerShell developers learning Terraform.

.EXAMPLE
    .\Start-TerraformLab-Clean.ps1
    
.EXAMPLE
    .\Start-TerraformLab-Clean.ps1 -Resume
    
.EXAMPLE
    .\Start-TerraformLab-Clean.ps1 -Exercise "01-basics/01-hello-world"
#>

[CmdletBinding()]
param(
    [switch]$Resume,
    [string]$Exercise,
    [switch]$ResetProgress,
    [switch]$ShowStats
)

$ErrorActionPreference = "Stop"

# Script Configuration
$script:LabVersion = "2.0.0"
$script:LabRoot = $PSScriptRoot
$script:ProgressFile = Join-Path $env:LOCALAPPDATA "TerraformLab\progress.json"
$script:ConfigFile = Join-Path $env:LOCALAPPDATA "TerraformLab\config.json"
$script:TerraformPath = "C:\Tools\Terraform\terraform.exe"

# Initialize progress tracking
$script:Progress = @{
    UserName = ""
    StartedAt = Get-Date
    CurrentExercise = ""
    CompletedExercises = @()
    TotalScore = 0
}

# Exercise definitions
$script:Exercises = @{
    "01-basics/01-hello-world" = @{
        Name = "Hello World - Your First Terraform Configuration"
        Description = "Learn basic Terraform syntax and create your first resources"
        Objectives = @(
            "Understand Terraform providers and resources",
            "Create local files using Terraform",
            "Compare Terraform to PowerShell concepts",
            "Run terraform init, plan, and apply commands"
        )
        EstimatedMinutes = 15
        Prerequisites = @()
        ValidationSteps = @(
            @{ Type = "FileExists"; Path = "terraform-lab-output/welcome.txt" },
            @{ Type = "FileExists"; Path = "terraform-lab-output/terraform-concepts.ps1" },
            @{ Type = "FileExists"; Path = "terraform-lab-output/example.tf" },
            @{ Type = "TerraformState"; MinResources = 3 }
        )
    }
    "01-basics/02-variables" = @{
        Name = "Variables and Data Types"
        Description = "Learn how to use variables and data types in Terraform"
        Objectives = @(
            "Define and use input variables",
            "Work with different data types (string, number, bool, list, map)",
            "Use local values and variable validation",
            "Create conditional resources"
        )
        EstimatedMinutes = 20
        Prerequisites = @("01-basics/01-hello-world")
        ValidationSteps = @(
            @{ Type = "FileExists"; Path = "output/config.json" },
            @{ Type = "FileExists"; Path = "output/monitoring.conf" },
            @{ Type = "DirectoryExists"; Path = "output/instances" },
            @{ Type = "TerraformState"; MinResources = 5 }
        )
    }
}

# UI Helper Functions
function Write-LabHeader {
    param(
        [string]$Title,
        [string]$Subtitle = ""
    )
    
    Clear-Host
    $width = [Math]::Min([Console]::WindowWidth, 80)
    $line = "=" * $width
    
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
    
    # Center the title
    $padding = [Math]::Max(0, ($width - $Title.Length) / 2)
    Write-Host (" " * $padding) -NoNewline
    Write-Host $Title -ForegroundColor Yellow -BackgroundColor DarkBlue
    
    if ($Subtitle) {
        Write-Host ""
        $padding = [Math]::Max(0, ($width - $Subtitle.Length) / 2)
        Write-Host (" " * $padding) -NoNewline
        Write-Host $Subtitle -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Show-Menu {
    param(
        [string]$Title,
        [array]$Options,
        [string]$Prompt = "Select an option"
    )
    
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ""
    
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
    
    Write-Info "Checking prerequisites..."
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

function Test-TerraformInstallation {
    Write-Info "Checking Terraform installation..."
    
    if (-not (Test-Path $script:TerraformPath)) {
        Write-Error "Terraform not found at $script:TerraformPath"
        Write-Host "Please ensure Terraform is installed and accessible." -ForegroundColor Yellow
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

function Invoke-TerraformCommand {
    param(
        [string]$Command,
        [string]$WorkingDirectory,
        [switch]$ShowOutput
    )
    
    Push-Location $WorkingDirectory
    try {
        Write-Info "Running: terraform $Command"
        
        $process = Start-Process -FilePath $script:TerraformPath -ArgumentList $Command -Wait -NoNewWindow -PassThru -RedirectStandardOutput "terraform-output.log" -RedirectStandardError "terraform-error.log"
        
        $output = Get-Content "terraform-output.log" -ErrorAction SilentlyContinue
        $errors = Get-Content "terraform-error.log" -ErrorAction SilentlyContinue
        
        if ($ShowOutput -and $output) {
            $output | ForEach-Object { Write-Host $_ }
        }
        
        if ($process.ExitCode -eq 0) {
            Write-Success "Command completed successfully"
            return @{ Success = $true; Output = $output; Errors = $errors }
        } else {
            Write-Error "Command failed with exit code $($process.ExitCode)"
            if ($errors) {
                $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
            }
            return @{ Success = $false; Output = $output; Errors = $errors }
        }
    } finally {
        Remove-Item "terraform-output.log" -ErrorAction SilentlyContinue
        Remove-Item "terraform-error.log" -ErrorAction SilentlyContinue
        Pop-Location
    }
}

function Test-ExerciseValidation {
    param([string]$ExerciseId)
    
    $exercise = $script:Exercises[$ExerciseId]
    $exercisePath = Join-Path $script:LabRoot $ExerciseId
    
    Write-Info "Validating exercise completion..."
    
    $allValid = $true
    foreach ($validation in $exercise.ValidationSteps) {
        switch ($validation.Type) {
            "FileExists" {
                $filePath = Join-Path $exercisePath $validation.Path
                if (Test-Path $filePath) {
                    Write-Success "File exists: $($validation.Path)"
                } else {
                    Write-Error "File missing: $($validation.Path)"
                    $allValid = $false
                }
            }
            "DirectoryExists" {
                $dirPath = Join-Path $exercisePath $validation.Path
                if (Test-Path $dirPath -PathType Container) {
                    Write-Success "Directory exists: $($validation.Path)"
                } else {
                    Write-Error "Directory missing: $($validation.Path)"
                    $allValid = $false
                }
            }
            "TerraformState" {
                $statePath = Join-Path $exercisePath "terraform.tfstate"
                if (Test-Path $statePath) {
                    try {
                        $state = Get-Content $statePath | ConvertFrom-Json
                        $resourceCount = $state.resources.Count
                        if ($resourceCount -ge $validation.MinResources) {
                            Write-Success "Terraform state valid: $resourceCount resources found"
                        } else {
                            Write-Error "Insufficient resources in state: $resourceCount (minimum: $($validation.MinResources))"
                            $allValid = $false
                        }
                    } catch {
                        Write-Error "Error reading Terraform state: $($_.Exception.Message)"
                        $allValid = $false
                    }
                } else {
                    Write-Error "Terraform state file not found"
                    $allValid = $false
                }
            }
        }
    }
    
    return $allValid
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
    
    # Check prerequisites
    if (-not (Test-Prerequisites $ExerciseId)) {
        Write-Warning "Please complete prerequisite exercises first."
        Read-Host "Press Enter to continue"
        return
    }
    
    # Show exercise introduction
    Write-LabHeader $exercise.Name $exercise.Description
    
    Write-Host "📚 Learning Objectives:" -ForegroundColor Cyan
    $exercise.Objectives | ForEach-Object {
        Write-Host "   • $_" -ForegroundColor White
    }
    Write-Host ""
    
    Write-Host "⏱️  Estimated Time: $($exercise.EstimatedMinutes) minutes" -ForegroundColor Yellow
    Write-Host "📁 Exercise Path: $exercisePath" -ForegroundColor Gray
    Write-Host ""
    
    $ready = Read-Host "Ready to start this exercise? (Y/n)"
    if ($ready -eq 'n') { return }
    
    # Start the interactive exercise session
    Start-ExerciseSession $ExerciseId $exercisePath
}

function Start-ExerciseSession {
    param(
        [string]$ExerciseId,
        [string]$ExercisePath
    )
    
    $script:Progress.CurrentExercise = $ExerciseId
    
    do {
        Write-LabHeader "Exercise: $ExerciseId" "Interactive Session"
        
        $menuOptions = @(
            "1. View exercise files",
            "2. Initialize Terraform (terraform init)",
            "3. Create execution plan (terraform plan)", 
            "4. Apply changes (terraform apply)",
            "5. Show current state (terraform show)",
            "6. Validate exercise completion",
            "7. Get hints and help",
            "8. Return to main menu"
        )
        
        $choice = Show-Menu "What would you like to do?" $menuOptions
        
        switch ($choice) {
            0 { Show-ExerciseFiles $ExercisePath }
            1 { Invoke-TerraformInit $ExercisePath }
            2 { Invoke-TerraformPlan $ExercisePath }
            3 { Invoke-TerraformApply $ExercisePath }
            4 { Invoke-TerraformShow $ExercisePath }
            5 { Test-ExerciseCompletion $ExerciseId $ExercisePath }
            6 { Show-ExerciseHints $ExerciseId }
            7 { return }
        }
        
        if ($choice -ne 7) {
            Write-Host ""
            Read-Host "Press Enter to continue"
        }
    } while ($true)
}

function Show-ExerciseFiles {
    param([string]$ExercisePath)
    
    Write-Info "Exercise files:"
    Get-ChildItem $ExercisePath -File | ForEach-Object {
        $icon = switch ($_.Extension) {
            ".tf" { "[TF]" }
            ".md" { "[MD]" }
            ".json" { "[JSON]" }
            ".yaml" { "[YAML]" }
            ".yml" { "[YAML]" }
            default { "[FILE]" }
        }
        Write-Host "   $icon $($_.Name)" -ForegroundColor White
    }
}

function Invoke-TerraformInit {
    param([string]$ExercisePath)
    
    Write-Info "Initializing Terraform..."
    $result = Invoke-TerraformCommand "init" $ExercisePath -ShowOutput
    
    if ($result.Success) {
        Write-Success "Terraform initialized successfully!"
    }
}

function Invoke-TerraformPlan {
    param([string]$ExercisePath)
    
    Write-Info "Creating execution plan..."
    $result = Invoke-TerraformCommand "plan" $ExercisePath -ShowOutput
    
    if ($result.Success) {
        Write-Success "Plan created successfully!"
        Write-Info "Review the plan above to understand what Terraform will create."
    }
}

function Invoke-TerraformApply {
    param([string]$ExercisePath)
    
    Write-Warning "This will create real resources. Are you sure? (y/N)"
    $confirm = Read-Host
    
    if ($confirm -ne 'y') {
        Write-Info "Apply cancelled."
        return
    }
    
    Write-Info "Applying Terraform configuration..."
    $result = Invoke-TerraformCommand "apply -auto-approve" $ExercisePath -ShowOutput
    
    if ($result.Success) {
        Write-Success "Configuration applied successfully!"
        Write-Info "Check the created files and outputs above."
    }
}

function Invoke-TerraformShow {
    param([string]$ExercisePath)
    
    Write-Info "Showing current state..."
    $result = Invoke-TerraformCommand "show" $ExercisePath -ShowOutput
    
    if ($result.Success) {
        Write-Success "State displayed successfully!"
    }
}

function Test-ExerciseCompletion {
    param(
        [string]$ExerciseId,
        [string]$ExercisePath
    )
    
    if (Test-ExerciseValidation $ExerciseId) {
        Write-Success "🎉 Exercise completed successfully!"
        
        if ($script:Progress.CompletedExercises -notcontains $ExerciseId) {
            $script:Progress.CompletedExercises += $ExerciseId
            $script:Progress.TotalScore += 100
            Save-Progress
            
            Write-Success "Progress saved! Total score: $($script:Progress.TotalScore)"
        }
        
        Write-Host ""
        Write-Host "*** Congratulations! You've mastered this exercise. ***" -ForegroundColor Green
        Write-Host ""
        
        # Show next exercise suggestion
        $nextExercise = Get-NextExercise $ExerciseId
        if ($nextExercise) {
            Write-Info "Ready for the next challenge? Try: $nextExercise"
        }
        
    } else {
        Write-Warning "Exercise not yet complete. Keep working!"
        Write-Info "Check the validation errors above and try again."
    }
}

function Show-ExerciseHints {
    param([string]$ExerciseId)
    
    Write-LabHeader "Hints and Help" $ExerciseId
    
    switch ($ExerciseId) {
        "01-basics/01-hello-world" {
            Write-Host @"
HINTS FOR HELLO WORLD EXERCISE:

1. Start with 'terraform init' to initialize the working directory
2. Use 'terraform plan' to see what will be created
3. Run 'terraform apply' to create the resources
4. Check the created files in the terraform-lab-output directory

TROUBLESHOOTING:
• If init fails: Check your internet connection for provider downloads
• If plan fails: Review the .tf files for syntax errors
• If apply fails: Check file permissions and disk space

LEARNING TIPS:
• Compare the .tf syntax to PowerShell - notice the similarities!
• Examine the terraform.tfstate file to understand state management
• Try running the created PowerShell script to see the comparison

"@ -ForegroundColor Yellow
        }
        "01-basics/02-variables" {
            Write-Host @"
HINTS FOR VARIABLES EXERCISE:

1. Notice how variables are defined vs PowerShell parameters
2. Check the variables.tf file to see different data types
3. Observe how variables are used in the main.tf file
4. Look at the outputs to see how data flows through

TROUBLESHOOTING:
• Variable errors: Check types and validation rules
• Missing outputs: Ensure all resources are created successfully
• File path issues: Variables control where files are created

LEARNING TIPS:
• Variables in Terraform = Parameters in PowerShell
• Locals in Terraform = Variables in PowerShell
• Try changing variable values and re-running plan/apply

"@ -ForegroundColor Yellow
        }
        default {
            Write-Info "No specific hints available for this exercise yet."
        }
    }
    
    Write-Host ""
    Read-Host "Press Enter to return"
}

function Get-NextExercise {
    param([string]$CurrentExercise)
    
    # Simple progression logic
    switch ($CurrentExercise) {
        "01-basics/01-hello-world" { return "01-basics/02-variables" }
        default { return $null }
    }
}

function Save-Progress {
    $progressDir = Split-Path $script:ProgressFile -Parent
    if (-not (Test-Path $progressDir)) {
        New-Item -Path $progressDir -ItemType Directory -Force | Out-Null
    }
    
    $script:Progress | ConvertTo-Json -Depth 10 | Set-Content $script:ProgressFile
}

function Load-Progress {
    if (Test-Path $script:ProgressFile) {
        try {
            $script:Progress = Get-Content $script:ProgressFile | ConvertFrom-Json
            # Convert arrays back to proper PowerShell arrays
            if ($script:Progress.CompletedExercises) {
                $script:Progress.CompletedExercises = [array]$script:Progress.CompletedExercises
            } else {
                $script:Progress.CompletedExercises = @()
            }
        } catch {
            Write-Warning "Could not load previous progress. Starting fresh."
        }
    }
}

function Show-MainMenu {
    do {
        $completed = $script:Progress.CompletedExercises.Count
        $total = $script:Exercises.Count
        
        Write-LabHeader "Terraform Learning Lab" "Progress: $completed/$total exercises completed"
        
        if ($script:Progress.UserName) {
            Write-Host "Welcome back, $($script:Progress.UserName)! " -ForegroundColor Green -NoNewline
            Write-Host "Score: $($script:Progress.TotalScore)" -ForegroundColor Cyan
        } else {
            Write-Host "Welcome to the Terraform Learning Lab!" -ForegroundColor Green
            $name = Read-Host "What's your name?"
            $script:Progress.UserName = $name
            Save-Progress
        }
        
        Write-Host ""
        
        $menuOptions = @(
            "Start Exercise: Hello World (Basics)",
            "Start Exercise: Variables and Data Types",
            "View Progress and Statistics",
            "Help and Documentation",
            "Reset Progress",
            "Exit Lab"
        )
        
        $choice = Show-Menu "What would you like to do today?" $menuOptions
        
        switch ($choice) {
            0 { Start-Exercise "01-basics/01-hello-world" }
            1 { Start-Exercise "01-basics/02-variables" }
            2 { Show-ProgressStats }
            3 { Show-Help }
            4 { Reset-Progress }
            5 { 
                Write-Info "Thank you for using the Terraform Learning Lab!"
                Write-Host "Keep practicing and happy Terraforming! 🌍" -ForegroundColor Green
                return 
            }
        }
    } while ($true)
}

function Show-ProgressStats {
    Write-LabHeader "Your Learning Progress"
    
    Write-Host "Student: $($script:Progress.UserName)" -ForegroundColor Green
    Write-Host "Started: $($script:Progress.StartedAt)" -ForegroundColor Cyan
    Write-Host "Total Score: $($script:Progress.TotalScore)" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Completed Exercises:" -ForegroundColor Cyan
    if ($script:Progress.CompletedExercises.Count -gt 0) {
        $script:Progress.CompletedExercises | ForEach-Object {
            Write-Success $_
        }
    } else {
        Write-Info "No exercises completed yet. Let's get started!"
    }
    
    Write-Host ""
    Write-Host "Available Exercises:" -ForegroundColor Cyan
    foreach ($exerciseId in $script:Exercises.Keys | Sort-Object) {
        $exercise = $script:Exercises[$exerciseId]
        $status = if ($script:Progress.CompletedExercises -contains $exerciseId) { "[DONE]" } else { "[TODO]" }
        Write-Host "   $status $($exercise.Name)" -ForegroundColor White
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Show-Help {
    Write-LabHeader "Help and Documentation"
    
    Write-Host @"
TERRAFORM LEARNING LAB HELP

This interactive lab guides you through learning Terraform from the ground up,
with special focus on concepts familiar to PowerShell developers.

HOW IT WORKS:
1. Select an exercise from the main menu
2. Follow the step-by-step interactive guidance
3. Run real Terraform commands with help and validation
4. Complete exercises to unlock new ones and track progress

EXERCISE WORKFLOW:
• View Files: Examine the Terraform configuration files
• Initialize: Run 'terraform init' to set up the working directory
• Plan: Run 'terraform plan' to preview changes
• Apply: Run 'terraform apply' to create resources
• Validate: Check that everything worked correctly

TIPS FOR SUCCESS:
• Start with the basics even if you have Terraform experience
• Read the .tf files carefully - they contain educational comments
• Use the hints feature if you get stuck
• Don't skip exercises - they build on each other
• Experiment! You can always start over

GETTING HELP:
• Each exercise has built-in hints (option 7 in exercise menu)
• Compare Terraform concepts to PowerShell equivalents
• Remember: Terraform is declarative, PowerShell is imperative

Happy learning!

"@ -ForegroundColor White
    
    Read-Host "Press Enter to continue"
}

function Reset-Progress {
    Write-Warning "This will reset ALL your progress. Are you sure? (y/N)"
    $confirm = Read-Host
    
    if ($confirm -eq 'y') {
        $script:Progress = @{
            UserName = ""
            StartedAt = Get-Date
            CurrentExercise = ""
            CompletedExercises = @()
            TotalScore = 0
        }
        Save-Progress
        Write-Success "Progress reset successfully!"
    } else {
        Write-Info "Reset cancelled."
    }
    
    Read-Host "Press Enter to continue"
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
        Reset-Progress
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