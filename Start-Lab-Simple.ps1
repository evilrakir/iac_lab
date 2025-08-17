# Simple Lab Runner for Testing
param(
    [string]$Exercise = ""
)

Clear-Host
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host " MODERN INFRASTRUCTURE AS CODE" -ForegroundColor Yellow
Write-Host " FOR WINDOWS ADMINS" -ForegroundColor Yellow  
Write-Host "====================================" -ForegroundColor Cyan
Write-Host " Terraform Mastery Course" -ForegroundColor White
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Simple menu
if (-not $Exercise) {
    Write-Host "Available Exercises:" -ForegroundColor Cyan
    Write-Host "  1. Hello World (01-basics/01-hello-world)" -ForegroundColor White
    Write-Host "  2. Variables (01-basics/02-variables)" -ForegroundColor White
    Write-Host "  3. Docker Provider (07-containers/01-docker-provider)" -ForegroundColor White
    Write-Host "  4. Kubernetes Basics (07-containers/02-kubernetes-basics)" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Select exercise number (1-4)"
    
    switch ($choice) {
        "1" { $Exercise = "01-basics/01-hello-world" }
        "2" { $Exercise = "01-basics/02-variables" }
        "3" { $Exercise = "07-containers/01-docker-provider" }
        "4" { $Exercise = "07-containers/02-kubernetes-basics" }
        default { 
            Write-Host "Invalid choice" -ForegroundColor Red
            exit 
        }
    }
}

Write-Host ""
Write-Host "Starting exercise: $Exercise" -ForegroundColor Green
Write-Host ""

# Check if exercise exists
$exercisePath = Join-Path $PSScriptRoot $Exercise
if (-not (Test-Path $exercisePath)) {
    # Try in workspace
    $exercisePath = $Exercise
    if (-not (Test-Path $exercisePath)) {
        Write-Host "Exercise not found: $Exercise" -ForegroundColor Red
        exit
    }
}

# Change to exercise directory
Write-Host "Navigating to: $exercisePath" -ForegroundColor Gray
Set-Location $exercisePath

# Show files
Write-Host ""
Write-Host "Exercise files:" -ForegroundColor Cyan
Get-ChildItem | Select-Object Name, Length | Format-Table

# Check for interactive guide
$guidePath = ".\interactive-guide.ps1"
if (Test-Path $guidePath) {
    Write-Host ""
    Write-Host "This exercise has an interactive guide!" -ForegroundColor Green
    $runGuide = Read-Host "Run the interactive guide? (Y/n)"
    if ($runGuide -ne 'n') {
        & $guidePath
        exit
    }
}

# Basic workflow
Write-Host ""
Write-Host "Basic Terraform Workflow:" -ForegroundColor Cyan
Write-Host "  1. terraform init    - Initialize providers" -ForegroundColor White
Write-Host "  2. terraform plan    - Preview changes" -ForegroundColor White
Write-Host "  3. terraform apply   - Apply changes" -ForegroundColor White
Write-Host "  4. terraform destroy - Clean up" -ForegroundColor White
Write-Host ""

Write-Host "You're now in the exercise directory." -ForegroundColor Green
Write-Host "Follow the workflow above or check README.md for instructions." -ForegroundColor Gray