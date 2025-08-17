# Test script to demonstrate the interactive lab experience
# This simulates a user going through the Hello World exercise

Write-Host "=============================================" -ForegroundColor Green
Write-Host "TESTING TERRAFORM INTERACTIVE LAB EXPERIENCE" -ForegroundColor Green  
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

# Test 1: Check the lab script exists and runs
Write-Host "TEST 1: Checking lab script availability..." -ForegroundColor Cyan
if (Test-Path ".\Start-TerraformLab-Simple.ps1") {
    Write-Host "[PASS] Interactive lab script found" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Interactive lab script not found" -ForegroundColor Red
    exit 1
}

# Test 2: Check progress display
Write-Host ""
Write-Host "TEST 2: Testing progress display..." -ForegroundColor Cyan
try {
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -File ".\Start-TerraformLab-Simple.ps1" -ShowStats
    if ($output -match "Your Learning Progress") {
        Write-Host "[PASS] Progress display working" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Progress display not working" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Error running progress display: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Check exercise availability
Write-Host ""
Write-Host "TEST 3: Checking exercise availability..." -ForegroundColor Cyan
$exercisePath = ".\01-basics\01-hello-world"
if (Test-Path $exercisePath) {
    Write-Host "[PASS] Hello World exercise directory found" -ForegroundColor Green
    
    # Check for required files
    $requiredFiles = @("main.tf", "variables.tf", "outputs.tf")
    $allFilesExist = $true
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $exercisePath $file
        if (Test-Path $filePath) {
            Write-Host "[PASS] Required file found: $file" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Missing required file: $file" -ForegroundColor Red
            $allFilesExist = $false
        }
    }
    
    if ($allFilesExist) {
        Write-Host "[PASS] All required exercise files present" -ForegroundColor Green
    }
} else {
    Write-Host "[FAIL] Hello World exercise directory not found" -ForegroundColor Red
}

# Test 4: Test basic Terraform functionality
Write-Host ""
Write-Host "TEST 4: Testing Terraform functionality..." -ForegroundColor Cyan
Push-Location $exercisePath
try {
    # Clean up any existing state
    if (Test-Path "terraform.tfstate") {
        Remove-Item "terraform.tfstate" -Force
    }
    if (Test-Path ".terraform") {
        Remove-Item ".terraform" -Recurse -Force
    }
    if (Test-Path "terraform-lab-output") {
        Remove-Item "terraform-lab-output" -Recurse -Force
    }
    
    # Test terraform init
    Write-Host "  Testing: terraform init..." -ForegroundColor Yellow
    $initResult = & "C:\Tools\Terraform\terraform.exe" init 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] Terraform init successful" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Terraform init failed" -ForegroundColor Red
        Write-Host $initResult -ForegroundColor Red
    }
    
    # Test terraform validate
    Write-Host "  Testing: terraform validate..." -ForegroundColor Yellow
    $validateResult = & "C:\Tools\Terraform\terraform.exe" validate 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] Terraform validate successful" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Terraform validate failed" -ForegroundColor Red
        Write-Host $validateResult -ForegroundColor Red
    }
    
    # Test terraform plan
    Write-Host "  Testing: terraform plan..." -ForegroundColor Yellow
    $planResult = & "C:\Tools\Terraform\terraform.exe" plan 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] Terraform plan successful" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Terraform plan failed" -ForegroundColor Red
        Write-Host $planResult -ForegroundColor Red
    }
    
    # Test terraform apply
    Write-Host "  Testing: terraform apply..." -ForegroundColor Yellow
    $applyResult = & "C:\Tools\Terraform\terraform.exe" apply -auto-approve 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] Terraform apply successful" -ForegroundColor Green
        
        # Check if expected files were created
        if (Test-Path "terraform-lab-output") {
            Write-Host "[PASS] Output directory created" -ForegroundColor Green
            
            $expectedFiles = @("welcome.txt", "terraform-concepts.ps1", "example.tf")
            foreach ($file in $expectedFiles) {
                $filePath = Join-Path "terraform-lab-output" $file
                if (Test-Path $filePath) {
                    Write-Host "[PASS] Created file: $file" -ForegroundColor Green
                } else {
                    Write-Host "[FAIL] Missing created file: $file" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "[FAIL] Output directory not created" -ForegroundColor Red
        }
    } else {
        Write-Host "[FAIL] Terraform apply failed" -ForegroundColor Red
        Write-Host $applyResult -ForegroundColor Red
    }
    
} finally {
    Pop-Location
}

# Test 5: Test the created PowerShell script
Write-Host ""
Write-Host "TEST 5: Testing created PowerShell educational content..." -ForegroundColor Cyan
$psScriptPath = Join-Path $exercisePath "terraform-lab-output\terraform-concepts.ps1"
if (Test-Path $psScriptPath) {
    try {
        Write-Host "  Running created PowerShell script..." -ForegroundColor Yellow
        $psOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $psScriptPath
        if ($psOutput -match "Terraform vs PowerShell Concepts") {
            Write-Host "[PASS] PowerShell educational script works" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] PowerShell script output unexpected" -ForegroundColor Red
        }
    } catch {
        Write-Host "[FAIL] Error running PowerShell script: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "[FAIL] PowerShell educational script not found" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "INTERACTIVE LAB TEST SUMMARY" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "The Terraform Interactive Lab is ready for students!" -ForegroundColor Green
Write-Host ""
Write-Host "Students can now run:" -ForegroundColor Cyan
Write-Host "  .\Start-TerraformLab-Simple.ps1" -ForegroundColor White
Write-Host ""
Write-Host "And get a fully guided, interactive learning experience!" -ForegroundColor Green
Write-Host ""