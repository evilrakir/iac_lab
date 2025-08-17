#Requires -Version 5.1
<#
.SYNOPSIS
    Initialize a separate user workspace for Terraform Lab exercises
.DESCRIPTION
    Creates a clean workspace where users can work on exercises without
    modifying the original lab files. This keeps the git repo clean.
.EXAMPLE
    .\Initialize-UserWorkspace.ps1
.EXAMPLE
    .\Initialize-UserWorkspace.ps1 -WorkspaceName "john-workspace"
#>
[CmdletBinding()]
param(
    [string]$WorkspaceName = "$env:USERNAME-workspace",
    [string]$WorkspacePath = (Join-Path $PSScriptRoot $WorkspaceName),
    [switch]$Reset,
    [switch]$SkipGitCheck
)

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
║   USER WORKSPACE INITIALIZATION                                 ║
║   Modern Infrastructure as Code for Windows Admins              ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`nThis script will create your personal workspace for the Terraform Lab."
Write-Host "Your workspace will be separate from the lab files and ignored by git."

# Check if we're in a git repo
if (-not $SkipGitCheck) {
    $gitStatus = git status 2>$null
    if ($?) {
        Write-Info "Git repository detected"
        
        # Check for uncommitted changes in lab files
        $changes = git status --porcelain 2>$null
        if ($changes) {
            Write-Warning "You have uncommitted changes in the repository"
            $continue = Read-Host "Continue anyway? (y/N)"
            if ($continue -ne 'y') {
                Write-Host "Initialization cancelled" -ForegroundColor Yellow
                exit 0
            }
        }
    }
}

# Check if workspace exists
if (Test-Path $WorkspacePath) {
    if ($Reset) {
        Write-Warning "Workspace exists and will be reset"
        $confirm = Read-Host "Delete existing workspace '$WorkspaceName'? (yes/no)"
        if ($confirm -eq 'yes') {
            Remove-Item -Path $WorkspacePath -Recurse -Force
            Write-Success "Existing workspace removed"
        } else {
            Write-Host "Reset cancelled" -ForegroundColor Yellow
            exit 0
        }
    } else {
        Write-Success "Workspace already exists: $WorkspacePath"
        Write-Info "Use -Reset to start fresh"
        $useExisting = Read-Host "`nUse existing workspace? (Y/n)"
        if ($useExisting -eq 'n') {
            exit 0
        }
    }
}

# Create workspace structure
Write-Step "Creating workspace structure"

if (-not (Test-Path $WorkspacePath)) {
    New-Item -ItemType Directory -Path $WorkspacePath -Force | Out-Null
    Write-Success "Created workspace: $WorkspaceName"
}

# Create subdirectories for exercises
$exerciseDirs = @(
    "01-basics",
    "02-providers", 
    "03-modules",
    "04-state",
    "05-best-practices",
    "06-advanced",
    "07-containers",
    "08-integrations",
    "09-legacy-optional"
)

foreach ($dir in $exerciseDirs) {
    $targetPath = Join-Path $WorkspacePath $dir
    if (-not (Test-Path $targetPath)) {
        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
    }
}

Write-Success "Exercise directories created"

# Copy exercise files (not user data)
Write-Step "Copying exercise templates"

foreach ($dir in $exerciseDirs) {
    $sourcePath = Join-Path $PSScriptRoot $dir
    $targetPath = Join-Path $WorkspacePath $dir
    
    if (Test-Path $sourcePath) {
        # Get subdirectories (individual exercises)
        $exercises = Get-ChildItem -Path $sourcePath -Directory
        
        foreach ($exercise in $exercises) {
            $exerciseSource = $exercise.FullName
            $exerciseTarget = Join-Path $targetPath $exercise.Name
            
            if (-not (Test-Path $exerciseTarget)) {
                New-Item -ItemType Directory -Path $exerciseTarget -Force | Out-Null
            }
            
            # Copy only .tf, .md, and .ps1 files (not state or output)
            $filesToCopy = Get-ChildItem -Path $exerciseSource -File | 
                Where-Object { 
                    $_.Extension -in @('.tf', '.md', '.ps1', '.yml', '.yaml', '.json') -and
                    $_.Name -notmatch '\.tfstate' -and
                    $_.Name -notmatch '\.lock\.hcl'
                }
            
            foreach ($file in $filesToCopy) {
                $targetFile = Join-Path $exerciseTarget $file.Name
                if (-not (Test-Path $targetFile)) {
                    Copy-Item -Path $file.FullName -Destination $targetFile
                }
            }
        }
    }
}

Write-Success "Exercise files copied"

# Create workspace configuration
Write-Step "Creating workspace configuration"

$workspaceConfig = @{
    WorkspaceName = $WorkspaceName
    CreatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    LabVersion = "2.0.0"
    User = $env:USERNAME
    MachineName = $env:COMPUTERNAME
}

$configPath = Join-Path $WorkspacePath ".workspace-config.json"
$workspaceConfig | ConvertTo-Json | Set-Content -Path $configPath
Write-Success "Workspace configuration saved"

# Create a workspace README
Write-Step "Creating workspace README"

$readmeContent = @"
# Your Personal Terraform Lab Workspace

This is your personal workspace for the Terraform Lab exercises.

## Important Notes

- ✅ This directory is **ignored by git** - feel free to experiment!
- ✅ Your progress is saved locally on your machine
- ✅ You can reset anytime with: ``.\Initialize-UserWorkspace.ps1 -Reset``
- ✅ Original lab files remain untouched

## Workspace Information

- **Created**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **User**: $env:USERNAME
- **Location**: $WorkspacePath

## How to Use

1. **Start the lab** from the main directory:
   ``````powershell
   # From the lab root directory
   .\Start-TerraformLab.ps1
   ``````

2. **Work on exercises** in this workspace:
   ``````powershell
   cd $WorkspaceName\01-basics\01-hello-world
   terraform init
   terraform plan
   terraform apply
   ``````

3. **Your work is automatically saved** in this workspace

## Getting Help

- Run ``.\Start-TerraformLab.ps1`` for the interactive guide
- Check ``.\scripts\Check-Environment.ps1`` for tool issues
- Each exercise has an ``interactive-guide.ps1`` script

## Resetting Your Workspace

If you want to start fresh:
``````powershell
.\Initialize-UserWorkspace.ps1 -Reset
``````

Happy learning! 🚀
"@

$readmePath = Join-Path $WorkspacePath "README.md"
$readmeContent | Set-Content -Path $readmePath
Write-Success "README created"

# Create shortcuts for convenience
Write-Step "Creating convenience scripts"

$startLabScript = @"
# Start the Terraform Lab from your workspace
& "$PSScriptRoot\Start-TerraformLab.ps1" @args
"@

$startLabPath = Join-Path $WorkspacePath "Start-Lab.ps1"
$startLabScript | Set-Content -Path $startLabPath
Write-Success "Created Start-Lab.ps1 shortcut"

# Final instructions
Write-Host "`n" -NoNewline
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ WORKSPACE INITIALIZED SUCCESSFULLY!                        ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📁 Your workspace is ready at:" -ForegroundColor Cyan
Write-Host "   $WorkspacePath" -ForegroundColor White

Write-Host "`n🚀 Next steps:" -ForegroundColor Cyan
Write-Host "   1. cd $WorkspaceName" -ForegroundColor White
Write-Host "   2. .\Start-Lab.ps1" -ForegroundColor White
Write-Host "      OR" -ForegroundColor Gray
Write-Host "   2. ..\Start-TerraformLab.ps1" -ForegroundColor White

Write-Host "`n💡 Tips:" -ForegroundColor Yellow
Write-Host "   • Your workspace is git-ignored - experiment freely!"
Write-Host "   • Run exercises from your workspace directory"
Write-Host "   • Original lab files remain untouched"
Write-Host "   • Use -Reset flag to start fresh anytime"

Write-Host "`n📚 Documentation:" -ForegroundColor Cyan
Write-Host "   • README.md in your workspace has more info"
Write-Host "   • Each exercise has an interactive-guide.ps1"
Write-Host "   • Run Check-Environment.ps1 to verify tools"

$startNow = Read-Host "`nWould you like to start the lab now? (Y/n)"
if ($startNow -ne 'n') {
    Write-Host "`nStarting Terraform Lab..." -ForegroundColor Green
    & (Join-Path $PSScriptRoot "Start-TerraformLab.ps1")
}