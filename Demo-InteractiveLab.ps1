# Demo script showing the key features of the Terraform Interactive Lab
# This demonstrates the capabilities without requiring interactive input

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "TERRAFORM INTERACTIVE LEARNING LAB - DEMO" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""

# Demo 1: Show the main features
Write-Host "DEMO 1: Interactive Lab Features" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The interactive lab provides:" -ForegroundColor White
Write-Host "  ✅ User-friendly menu system" -ForegroundColor Green
Write-Host "  ✅ Progress tracking across sessions" -ForegroundColor Green  
Write-Host "  ✅ Exercise validation and completion checking" -ForegroundColor Green
Write-Host "  ✅ Step-by-step guided workflow" -ForegroundColor Green
Write-Host "  ✅ Help and troubleshooting for each exercise" -ForegroundColor Green
Write-Host "  ✅ PowerShell-to-Terraform concept mapping" -ForegroundColor Green
Write-Host ""

# Demo 2: Show current progress
Write-Host "DEMO 2: Current Student Progress" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Running: .\Start-TerraformLab-Simple.ps1 -ShowStats" -ForegroundColor Yellow
Write-Host ""
& .\Start-TerraformLab-Simple.ps1 -ShowStats
Write-Host ""

# Demo 3: Show exercise structure
Write-Host "DEMO 3: Available Learning Exercises" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Exercise 1: Hello World (01-basics/01-hello-world)" -ForegroundColor White
Write-Host "  📚 Learn: Basic Terraform syntax, providers, resources" -ForegroundColor Gray
Write-Host "  🎯 Create: Local files with educational content" -ForegroundColor Gray
Write-Host "  🔍 Compare: Terraform vs PowerShell concepts" -ForegroundColor Gray
Write-Host ""
Write-Host "Exercise 2: Variables (01-basics/02-variables)" -ForegroundColor White  
Write-Host "  📚 Learn: Input variables, data types, validation" -ForegroundColor Gray
Write-Host "  🎯 Create: Configuration files with variable usage" -ForegroundColor Gray
Write-Host "  🔍 Compare: Terraform variables vs PowerShell parameters" -ForegroundColor Gray
Write-Host ""

# Demo 4: Show validation capabilities
Write-Host "DEMO 4: Exercise Validation Capabilities" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The lab automatically validates:" -ForegroundColor White
Write-Host "  ✅ Prerequisites completed before starting new exercises" -ForegroundColor Green
Write-Host "  ✅ Terraform state files exist and contain resources" -ForegroundColor Green
Write-Host "  ✅ Expected output files and directories created" -ForegroundColor Green
Write-Host "  ✅ Exercise completion status and scoring" -ForegroundColor Green
Write-Host ""

# Demo 5: Show created educational content
Write-Host "DEMO 5: Educational Content Created" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""
$outputDir = ".\01-basics\01-hello-world\terraform-lab-output"
if (Test-Path $outputDir) {
    Write-Host "Exercise creates real educational files:" -ForegroundColor White
    Get-ChildItem $outputDir | ForEach-Object {
        Write-Host "  📄 $($_.Name) ($($_.Length) bytes)" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Show the PowerShell educational script in action
    $psScript = Join-Path $outputDir "terraform-concepts.ps1"
    if (Test-Path $psScript) {
        Write-Host "Running the created PowerShell educational script:" -ForegroundColor Yellow
        Write-Host ""
        & $psScript
        Write-Host ""
    }
} else {
    Write-Host "No output files found. Run the Hello World exercise to see this demo." -ForegroundColor Yellow
    Write-Host ""
}

# Demo 6: Show how to start the lab
Write-Host "DEMO 6: How Students Use the Lab" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Students simply run:" -ForegroundColor White
Write-Host "  .\Start-TerraformLab-Simple.ps1" -ForegroundColor Green
Write-Host ""
Write-Host "And get an interactive menu with options:" -ForegroundColor White
Write-Host "  1. Start Exercise: Hello World (Basics)" -ForegroundColor Gray
Write-Host "  2. Start Exercise: Variables and Data Types" -ForegroundColor Gray
Write-Host "  3. View Progress and Statistics" -ForegroundColor Gray
Write-Host "  4. Help and Documentation" -ForegroundColor Gray
Write-Host "  5. Exit Lab" -ForegroundColor Gray
Write-Host ""

Write-Host "Within each exercise, students get a guided workflow:" -ForegroundColor White
Write-Host "  1. View exercise files" -ForegroundColor Gray
Write-Host "  2. Initialize Terraform (terraform init)" -ForegroundColor Gray
Write-Host "  3. Create execution plan (terraform plan)" -ForegroundColor Gray
Write-Host "  4. Apply changes (terraform apply)" -ForegroundColor Gray
Write-Host "  5. Show current state (terraform show)" -ForegroundColor Gray
Write-Host "  6. Validate exercise completion" -ForegroundColor Gray
Write-Host "  7. Return to main menu" -ForegroundColor Gray
Write-Host ""

# Demo 7: Summary
Write-Host "DEMO 7: Lab Benefits Summary" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "FOR STUDENTS:" -ForegroundColor Green
Write-Host "  • No intimidation - guided step-by-step learning" -ForegroundColor White
Write-Host "  • Immediate validation and feedback" -ForegroundColor White
Write-Host "  • PowerShell concepts mapped to Terraform" -ForegroundColor White
Write-Host "  • Safe learning environment (local files only)" -ForegroundColor White
Write-Host "  • Progress tracking and achievement system" -ForegroundColor White
Write-Host ""
Write-Host "FOR INSTRUCTORS:" -ForegroundColor Green
Write-Host "  • No setup required - works out of the box" -ForegroundColor White
Write-Host "  • Built-in help and troubleshooting" -ForegroundColor White
Write-Host "  • Student progress visibility" -ForegroundColor White
Write-Host "  • Consistent learning experience" -ForegroundColor White
Write-Host "  • Easy to extend with new exercises" -ForegroundColor White
Write-Host ""

Write-Host "=======================================================" -ForegroundColor Green
Write-Host "READY FOR PRODUCTION USE!" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "The Terraform Interactive Learning Lab is fully" -ForegroundColor White
Write-Host "functional and ready for students to use!" -ForegroundColor White
Write-Host ""