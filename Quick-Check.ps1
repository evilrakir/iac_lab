# Quick environment check for testing
Write-Host "`n=== Quick Environment Check ===" -ForegroundColor Cyan

# Check Terraform
$terraform = Get-Command terraform -ErrorAction SilentlyContinue
if ($terraform) {
    Write-Host "✅ Terraform installed" -ForegroundColor Green
    terraform version
} else {
    Write-Host "❌ Terraform not found" -ForegroundColor Red
}

# Check Docker
Write-Host "`nChecking Docker..." -ForegroundColor Cyan
$dockerVersion = docker version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Docker is running" -ForegroundColor Green
} else {
    Write-Host "⚠️  Docker not running or not installed" -ForegroundColor Yellow
}

# Check kubectl
$kubectl = Get-Command kubectl -ErrorAction SilentlyContinue  
if ($kubectl) {
    Write-Host "✅ kubectl installed" -ForegroundColor Green
} else {
    Write-Host "⚠️  kubectl not found" -ForegroundColor Yellow
}

Write-Host "`nReady to start the lab!" -ForegroundColor Green