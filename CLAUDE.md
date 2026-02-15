# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Interactive Terraform Learning Lab for Windows administrators transitioning to Infrastructure as Code. Built with PowerShell-native tooling, exercises progress from basics to advanced topics. All core exercises use the `local` provider so no cloud accounts are needed.

## Key Commands

### Running the Lab (for students)
```powershell
.\Setup-Lab.ps1                                          # Create user workspace
.\Start-TerraformLab.ps1                                 # Interactive lab runner
.\Start-TerraformLab.ps1 -Exercise "01-basics/02-variables"  # Start specific exercise
.\Start-TerraformLab.ps1 -ShowStats                      # View progress
.\Start-TerraformLab.ps1 -ResetProgress                  # Reset all progress
.\Start-TerraformLab.ps1 -SkipPrerequisites              # Skip prerequisite checks
```

### Validating Exercises (for development)
```powershell
# Test an exercise end-to-end
cd 01-basics/01-hello-world
terraform init
terraform validate
terraform apply -auto-approve
terraform destroy -auto-approve
# Clean up artifacts
Remove-Item -Recurse -Force .terraform, .terraform.lock.hcl, terraform.tfstate*, terraform-lab-output
```

### Utility Scripts
```powershell
.\Install-TerraformUser.ps1          # Install Terraform without admin (user PATH)
.\utilities\Quick-Check.ps1          # Verify environment prerequisites
.\utilities\Test-InteractiveLab.ps1  # Automated lab testing
```

## Architecture

### Exercise Structure
Each exercise directory follows this pattern:
- `main.tf` - Primary resource definitions with extensive educational comments
- `variables.tf` - Input variables with validation (separate file in 01-basics)
- `outputs.tf` - Output values (separate file in 01-basics)
- `README.md` - Exercise documentation and learning objectives
- All file output goes to `./terraform-lab-output/` (gitignored)

### Interactive Lab System
`Start-TerraformLab.ps1` is the main entry point (~1000 lines):
- Exercise definitions with prerequisites and difficulty levels in `$script:Exercises` hashtable
- Guided mode walks students through init/plan/apply/show/destroy with command prompts
- Progress stored in `$env:APPDATA\TerraformLab\progress.json` (not in repo)
- Completion tracked via `.terraform-lab-completed` marker files
- Terraform binary expected at `C:\Tools\Terraform\terraform.exe`

### Lab Sections and Completion Status
| Section | Complete | Status |
|---------|----------|--------|
| 01-basics (5 exercises) | 5/5 | All functional with full educational content |
| 02-providers (6 exercises) | 2/6 | local-provider + openstack complete |
| 03-modules (5 exercises) | 1/5 | simple-module complete |
| 04-state (5 exercises) | 1/5 | local-state complete |
| 05-best-practices (5 exercises) | 0/5 | All placeholder |
| 06-advanced (5 exercises) | 1/5 | conditional-resources complete |
| 07-containers (6 exercises) | 2/6 | docker-basics + docker-provider complete |
| 08-integrations (4 exercises) | 1/4 | terraform-ansible complete |
| 09-legacy-optional (3 exercises) | 1/3 | vagrant complete |

Exercises marked "Coming Soon" have valid placeholder `main.tf` files that pass `terraform validate`.

### Exercise Conventions
- PowerShell comparison comments in every completed exercise (e.g., `terraform plan` = `-WhatIf`)
- PowerShell comparison scripts generated as output: `terraform-vs-powershell-*.ps1`
- Template files use `.tftpl` extension
- Conditional resources use `count = var.flag ? 1 : 0` pattern
- Complex iteration uses `for_each` with maps/sets

### Workspace Isolation
- Students work in `<username>-workspace/` directories (gitignored)
- `Setup-Lab.ps1` copies exercise structure into workspace
- Exercises can also run directly in their source directories

## Development Guidelines

### When Creating New Exercises
1. Follow the standard file structure: `main.tf`, `variables.tf`, `outputs.tf`, `README.md`
2. Add heavy inline comments explaining each concept with PowerShell comparisons
3. Output files go to `./terraform-lab-output/` - never pollute the exercise directory
4. Add the exercise to `$script:Exercises` in `Start-TerraformLab.ps1` with name, description, prerequisites, and difficulty
5. Include variable validation blocks and descriptions
6. Generate a PowerShell comparison script as an output file
7. Test the full cycle: `init` -> `validate` -> `apply` -> `show` -> `destroy` -> cleanup
8. Handle null values in templates with conditionals

### Key Files for Lab Infrastructure
- `Start-TerraformLab.ps1` - Main lab runner, exercise registry, guided mode
- `Setup-Lab.ps1` - Workspace creation (copies exercise dirs)
- `Install-TerraformUser.ps1` - User-level Terraform installer
- `scripts/modules/LabValidation.psm1` - Validation framework
- `BEST_PRACTICES.md` - Detailed standards for exercise development
- `TODO_BEST_PRACTICES.md` - Tracking which exercises need updates
- `LAB_INVENTORY.md` - Quick status of all exercises
