# Interactive Guide for Exercise: Hello World
# This script provides step-by-step guidance through the exercise

param(
    [switch]$AutoRun
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Text, [int]$Number)
    Write-Host "`n" -NoNewline
    Write-Host "[$Number]" -ForegroundColor Yellow -NoNewline
    Write-Host " $Text" -ForegroundColor Cyan
}

function Write-Instruction {
    param([string]$Text)
    Write-Host "    → $Text" -ForegroundColor White
}

function Write-Tip {
    param([string]$Text)
    Write-Host "    💡 TIP: $Text" -ForegroundColor Green
}

function Write-WindowsNote {
    param([string]$Text)
    Write-Host "    🪟 WINDOWS: $Text" -ForegroundColor Blue
}

function Wait-ForUser {
    if (-not $AutoRun) {
        Write-Host "`n    Press Enter to continue..." -ForegroundColor Gray
        Read-Host
    }
}

function Test-LastCommand {
    param([string]$ExpectedOutput)
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    ✅ Success!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "    ❌ Command failed. Check the error above." -ForegroundColor Red
        return $false
    }
}

# Start the interactive guide
Clear-Host
Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║   HELLO WORLD - YOUR FIRST TERRAFORM CONFIGURATION            ║
║   Interactive Guided Exercise for Windows Admins              ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`nWelcome Windows Admin! This interactive guide will walk you through"
Write-Host "creating your first Terraform configuration step by step."
Write-Host ""
Write-Host "As a Windows admin, you'll find Terraform similar to PowerShell DSC"
Write-Host "but works across all cloud providers and platforms!"

Wait-ForUser

# Step 1: Check Environment
Write-Step "Environment Check" 1
Write-Instruction "Let's verify Terraform is installed and ready"

$terraform = Get-Command terraform -ErrorAction SilentlyContinue
if ($terraform) {
    $version = terraform version -json 2>$null | ConvertFrom-Json
    Write-Host "    ✅ Terraform $($version.terraform_version) is installed" -ForegroundColor Green
} else {
    Write-Host "    ❌ Terraform not found!" -ForegroundColor Red
    Write-Instruction "Run: .\scripts\Install-LabTools.ps1 -Core"
    exit 1
}

Write-WindowsNote "Terraform on Windows works just like on Linux - same commands!"

Wait-ForUser

# Step 2: Explore the configuration
Write-Step "Explore the Terraform Configuration" 2
Write-Instruction "Open main.tf in your editor to see the configuration"

if (Test-Path "main.tf") {
    Write-Host "    📄 main.tf found" -ForegroundColor Green
    
    Write-Host "`n    Key concepts in this file:" -ForegroundColor Yellow
    Write-Host "    • terraform {} block - Configures Terraform and providers"
    Write-Host "    • provider {} block - Configures the provider (local in this case)"  
    Write-Host "    • resource {} blocks - Define infrastructure to create"
    Write-Host "    • variable {} blocks - Define input parameters"
    
    Write-Tip "The 'local' provider creates files/directories on your Windows machine"
    Write-WindowsNote "No cloud account needed for this exercise!"
} else {
    Write-Host "    ❌ main.tf not found. Are you in the right directory?" -ForegroundColor Red
    Write-Host "    Current directory: $(Get-Location)" -ForegroundColor Gray
    exit 1
}

$openEditor = Read-Host "`n    Would you like to open the file in VS Code? (Y/n)"
if ($openEditor -ne 'n') {
    code main.tf 2>$null
}

Wait-ForUser

# Step 3: Initialize Terraform
Write-Step "Initialize Terraform" 3
Write-Instruction "Download the provider plugins and initialize the working directory"

Write-Host "`n    Running: terraform init" -ForegroundColor Yellow
Write-Host ""

terraform init

if (Test-LastCommand) {
    Write-Tip "The .terraform folder now contains the downloaded provider"
    Write-WindowsNote "This is like Install-Module in PowerShell"
}

Wait-ForUser

# Step 4: Review the plan
Write-Step "Preview Changes with Plan" 4
Write-Instruction "See what Terraform will create before actually creating it"

Write-Host "`n    Running: terraform plan" -ForegroundColor Yellow
Write-Host ""

terraform plan -out=tfplan

if (Test-LastCommand) {
    Write-Tip "The plan shows resources to be created (green +)"
    Write-WindowsNote "This is like -WhatIf in PowerShell!"
    Write-Host "`n    Plan saved to 'tfplan' file for apply" -ForegroundColor Gray
}

Wait-ForUser

# Step 5: Apply the configuration
Write-Step "Apply the Configuration" 5
Write-Instruction "Create the actual resources defined in your configuration"

$apply = Read-Host "`n    Ready to create the resources? (yes/no)"
if ($apply -eq "yes") {
    Write-Host "`n    Running: terraform apply tfplan" -ForegroundColor Yellow
    Write-Host ""
    
    terraform apply tfplan
    
    if (Test-LastCommand) {
        Write-Tip "Resources created! Check the terraform-lab-output folder"
        Write-WindowsNote "Terraform tracks state in terraform.tfstate file"
    }
} else {
    Write-Host "    Skipping apply. Run 'terraform apply' when ready." -ForegroundColor Yellow
}

Wait-ForUser

# Step 6: Verify the results
Write-Step "Verify the Results" 6
Write-Instruction "Let's check what Terraform created"

if (Test-Path "terraform-lab-output") {
    Write-Host "    ✅ Directory created: terraform-lab-output" -ForegroundColor Green
    
    $files = Get-ChildItem "terraform-lab-output" -File
    if ($files) {
        Write-Host "`n    Files created:" -ForegroundColor Yellow
        $files | ForEach-Object {
            Write-Host "    • $($_.Name)" -ForegroundColor White
        }
    }
    
    # Show welcome.txt content
    $welcomeFile = "terraform-lab-output\welcome.txt"
    if (Test-Path $welcomeFile) {
        Write-Host "`n    Content of welcome.txt:" -ForegroundColor Yellow
        Get-Content $welcomeFile | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "    ⚠️  Output directory not found. Did you run apply?" -ForegroundColor Yellow
}

Write-WindowsNote "Check terraform.tfstate to see how Terraform tracks resources"

Wait-ForUser

# Step 7: Understanding State
Write-Step "Understanding Terraform State" 7
Write-Instruction "Terraform tracks what it manages in a state file"

if (Test-Path "terraform.tfstate") {
    $state = Get-Content "terraform.tfstate" -Raw | ConvertFrom-Json
    Write-Host "    ✅ State file exists" -ForegroundColor Green
    Write-Host "    • Version: $($state.version)" -ForegroundColor White
    Write-Host "    • Resources tracked: $($state.resources.Count)" -ForegroundColor White
    
    Write-Tip "Never edit the state file directly!"
    Write-WindowsNote "State is like the MOF file in PowerShell DSC"
} else {
    Write-Host "    ⚠️  No state file yet. Run 'terraform apply' first." -ForegroundColor Yellow
}

Wait-ForUser

# Step 8: Make changes
Write-Step "Making Changes" 8
Write-Instruction "Modify the configuration and see Terraform detect changes"

Write-Host @"
    
    Try this experiment:
    1. Edit variables.tf and change lab_path default value
    2. Run 'terraform plan' to see the changes
    3. Run 'terraform apply' to apply changes
    
    Terraform will:
    • Detect the change
    • Show you what will be modified
    • Update only what changed
"@ -ForegroundColor White

Write-WindowsNote "Like PowerShell DSC, Terraform ensures desired state"

Wait-ForUser

# Step 9: Clean up
Write-Step "Clean Up Resources" 9
Write-Instruction "Remove all resources created by Terraform"

$destroy = Read-Host "`n    Ready to destroy the resources? (yes/no)"
if ($destroy -eq "yes") {
    Write-Host "`n    Running: terraform destroy" -ForegroundColor Yellow
    Write-Host ""
    
    terraform destroy -auto-approve
    
    if (Test-LastCommand) {
        Write-Host "    ✅ All resources destroyed!" -ForegroundColor Green
        Write-WindowsNote "The state file tracks that resources were deleted"
    }
} else {
    Write-Host "    Run 'terraform destroy' when you're ready to clean up" -ForegroundColor Yellow
}

# Completion
Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   🎉 CONGRATULATIONS! Exercise Complete!                      ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host @"

You've learned:
✅ How to write a basic Terraform configuration
✅ Initialize a Terraform working directory  
✅ Preview changes with 'terraform plan'
✅ Apply changes with 'terraform apply'
✅ Understand state management
✅ Destroy resources with 'terraform destroy'

🎯 Key Takeaways for Windows Admins:
• Terraform is declarative like PowerShell DSC
• Works across all platforms (Windows, Linux, Cloud)
• State tracking ensures consistency
• Plan = -WhatIf, Apply = Invoke-DscResource

📚 Next Steps:
• Try exercise 02-variables to learn about inputs
• Experiment with changing the configuration
• Explore the state file structure

"@ -ForegroundColor Cyan

Write-Host "Return to main menu: .\Start-TerraformLab.ps1" -ForegroundColor Yellow