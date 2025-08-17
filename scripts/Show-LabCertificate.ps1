# Show-LabCertificate.ps1 - Generate completion certificates for Terraform Lab

param(
    [string]$UserName,
    [string]$Achievement = "Terraform Fundamentals",
    [datetime]$CompletionDate = (Get-Date),
    [int]$ExercisesCompleted = 0,
    [int]$TotalExercises = 0,
    [switch]$SaveToFile,
    [string]$OutputPath = "$env:USERPROFILE\Documents\TerraformLabCertificate.txt"
)

function Get-CompletionBadge {
    param([int]$Percentage)
    
    if ($Percentage -eq 100) {
        return "🌟 MASTER 🌟"
    } elseif ($Percentage -ge 90) {
        return "⭐ EXPERT ⭐"
    } elseif ($Percentage -ge 75) {
        return "🏆 ADVANCED"
    } elseif ($Percentage -ge 50) {
        return "🎯 PRACTITIONER"
    } elseif ($Percentage -ge 25) {
        return "📚 STUDENT"
    } else {
        return "🚀 BEGINNER"
    }
}

function Show-Certificate {
    param(
        [string]$Name,
        [string]$Achievement,
        [string]$Date,
        [string]$Badge,
        [int]$Completed,
        [int]$Total
    )
    
    $percentage = if ($Total -gt 0) { [math]::Round(($Completed / $Total) * 100) } else { 0 }
    
    $certificate = @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                     🏅 CERTIFICATE OF ACHIEVEMENT 🏅                        ║
║                                                                              ║
║                   MODERN INFRASTRUCTURE AS CODE                             ║
║                        FOR WINDOWS ADMINS                                   ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║                          This certifies that                                ║
║                                                                              ║
║                         $Name
║                                                                              ║
║                    has successfully completed                               ║
║                                                                              ║
║                       $Achievement
║                                                                              ║
║                     in the Terraform Mastery Course                         ║
║                                                                              ║
║                        Achievement Level:                                   ║
║                         $Badge
║                                                                              ║
║                    Exercises Completed: $Completed/$Total ($percentage%)
║                                                                              ║
║                         Date: $Date
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║   Skills Demonstrated:                                                      ║
║   ✓ Infrastructure as Code with Terraform                                   ║
║   ✓ PowerShell Integration & Automation                                     ║
║   ✓ Container & Kubernetes Management                                       ║
║   ✓ Cloud Provider Configuration                                            ║
║   ✓ Modern DevOps Practices                                                 ║
║                                                                              ║
║                 🔧 PowerShell Native | ☁️ Cloud Ready | 🐋 Container First    ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

                        Terraform Lab - Windows Admin Edition
                              Bridging Legacy to Cloud
"@
    
    return $certificate
}

# Generate the certificate
$badge = Get-CompletionBadge -Percentage $(if ($TotalExercises -gt 0) { ($ExercisesCompleted / $TotalExercises) * 100 } else { 0 })

# Format name for certificate (center it)
$maxNameLength = 40
$paddedName = if ($UserName.Length -lt $maxNameLength) {
    $padding = [math]::Floor(($maxNameLength - $UserName.Length) / 2)
    (" " * $padding) + $UserName.ToUpper()
} else {
    $UserName.ToUpper()
}

# Format achievement
$paddedAchievement = if ($Achievement.Length -lt $maxNameLength) {
    $padding = [math]::Floor(($maxNameLength - $Achievement.Length) / 2)
    (" " * $padding) + $Achievement
} else {
    $Achievement
}

# Format badge
$paddedBadge = if ($badge.Length -lt $maxNameLength) {
    $padding = [math]::Floor(($maxNameLength - $badge.Length) / 2)
    (" " * $padding) + $badge
} else {
    $badge
}

$cert = Show-Certificate -Name $paddedName `
                        -Achievement $paddedAchievement `
                        -Date $CompletionDate.ToString("MMMM dd, yyyy") `
                        -Badge $paddedBadge `
                        -Completed $ExercisesCompleted `
                        -Total $TotalExercises

# Display certificate
Clear-Host
Write-Host $cert -ForegroundColor Cyan

# Save to file if requested
if ($SaveToFile) {
    $cert | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "`n📄 Certificate saved to: $OutputPath" -ForegroundColor Green
}

# Add achievements based on completion
Write-Host "`n🎯 ACHIEVEMENTS UNLOCKED:" -ForegroundColor Yellow

if ($ExercisesCompleted -ge 1) {
    Write-Host "  ⭐ First Steps - Completed your first Terraform exercise" -ForegroundColor Green
}
if ($ExercisesCompleted -ge 5) {
    Write-Host "  ⭐⭐ Infrastructure Builder - Completed 5 exercises" -ForegroundColor Green  
}
if ($ExercisesCompleted -ge 10) {
    Write-Host "  ⭐⭐⭐ Terraform Practitioner - Completed 10 exercises" -ForegroundColor Green
}
if ($ExercisesCompleted -ge 15) {
    Write-Host "  🏆 Cloud Architect - Completed 15 exercises" -ForegroundColor Green
}
if ($TotalExercises -gt 0 -and $ExercisesCompleted -eq $TotalExercises) {
    Write-Host "  🌟🌟🌟 TERRAFORM MASTER - Completed ALL exercises!" -ForegroundColor Yellow
    Write-Host "  🎊 WINDOWS ADMIN ELITE - Mastered Modern Infrastructure as Code!" -ForegroundColor Magenta
}

# Special achievements
$percentage = if ($TotalExercises -gt 0) { ($ExercisesCompleted / $TotalExercises) * 100 } else { 0 }

Write-Host "`n📊 STATISTICS:" -ForegroundColor Cyan
Write-Host "  Progress: $ExercisesCompleted/$TotalExercises exercises ($([math]::Round($percentage))%)" -ForegroundColor White
Write-Host "  Completion Date: $($CompletionDate.ToString('yyyy-MM-dd'))" -ForegroundColor White

# Progress bar
Write-Host "`n  Progress Bar:" -ForegroundColor Gray
$barLength = 50
$filled = [math]::Round(($percentage / 100) * $barLength)
$empty = $barLength - $filled
Write-Host "  [" -NoNewline
Write-Host ("█" * $filled) -ForegroundColor Green -NoNewline
Write-Host ("░" * $empty) -ForegroundColor DarkGray -NoNewline
Write-Host "] $([math]::Round($percentage))%"

# Motivational message
Write-Host "`n💬 MESSAGE:" -ForegroundColor Cyan
if ($percentage -eq 100) {
    Write-Host @"
  Congratulations! You've mastered Modern Infrastructure as Code!
  You're now equipped to manage infrastructure across Windows, Linux,
  containers, and cloud platforms using Terraform. Your PowerShell
  background combined with Terraform expertise makes you a powerful
  force in modern DevOps!
"@ -ForegroundColor Green
} elseif ($percentage -ge 75) {
    Write-Host @"
  Excellent progress! You're well on your way to mastering Terraform.
  Keep pushing through the remaining exercises to complete your journey
  from Windows Admin to Cloud Infrastructure Expert!
"@ -ForegroundColor Green
} elseif ($percentage -ge 50) {
    Write-Host @"
  Great job! You're halfway through your transformation journey.
  Each exercise builds on the last, taking you closer to modern
  infrastructure mastery. Keep going!
"@ -ForegroundColor Yellow
} else {
    Write-Host @"
  You're just getting started on an exciting journey! Each exercise
  you complete brings you closer to bridging traditional Windows
  administration with modern cloud infrastructure. Keep learning!
"@ -ForegroundColor Cyan
}

Write-Host "`n🔗 Share your achievement:" -ForegroundColor Yellow
Write-Host "  LinkedIn: #TerraformLab #InfrastructureAsCode #WindowsAdmin #DevOps" -ForegroundColor Gray
Write-Host "  Twitter/X: I just completed $ExercisesCompleted exercises in the Terraform Lab! 🚀" -ForegroundColor Gray

Write-Host "`n"