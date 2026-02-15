# ╔════════════════════════════════════════════════════════════════════╗
# ║  GITOPS WORKFLOW WITH TERRAFORM                                  ║
# ║  Version-controlled infrastructure with automated pipelines     ║
# ╚════════════════════════════════════════════════════════════════════╝

# GitOps applies Git best practices to infrastructure: all changes go
# through pull requests, are reviewed by peers, and are automatically
# applied by CI/CD pipelines. This exercise generates pipeline configs
# and workflow documentation using the local provider.

# POWERSHELL COMPARISON:
# =====================
# Like storing PowerShell deployment scripts in Git and using
# Azure DevOps pipelines to run them on merge:
#   git push -> PR review -> merge -> pipeline runs Deploy-Infrastructure.ps1
# With Terraform: git push -> PR (auto plan) -> merge -> auto apply

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

# ========================================================================
# VARIABLES
# ========================================================================

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "terraform-lab"
}

variable "git_branch" {
  description = "Primary branch name"
  type        = string
  default     = "main"
}

# ========================================================================
# SECTION 1: GITHUB ACTIONS WORKFLOW
# ========================================================================

resource "local_file" "github_actions" {
  filename = "./terraform-lab-output/gitops/github-actions-terraform.yml"
  content  = <<-EOT
    # GitHub Actions: Terraform CI/CD Pipeline
    # ==========================================
    # Runs plan on PR, apply on merge to main

    name: Terraform

    on:
      pull_request:
        branches: [${var.git_branch}]
        paths:
          - 'terraform/**'
          - '.github/workflows/terraform.yml'
      push:
        branches: [${var.git_branch}]
        paths:
          - 'terraform/**'

    permissions:
      contents: read
      pull-requests: write    # For PR comments

    env:
      TF_VERSION: '1.6.0'
      WORKING_DIR: './terraform'

    jobs:
      # ---- PLAN (runs on every PR) ----
      plan:
        name: Terraform Plan
        runs-on: ubuntu-latest
        if: github.event_name == 'pull_request'

        steps:
          - name: Checkout code
            uses: actions/checkout@v4

          - name: Setup Terraform
            uses: hashicorp/setup-terraform@v3
            with:
              terraform_version: $TF_VERSION

          - name: Terraform Init
            working-directory: $WORKING_DIR
            run: terraform init -no-color

          - name: Terraform Validate
            working-directory: $WORKING_DIR
            run: terraform validate -no-color

          - name: Terraform Plan
            id: plan
            working-directory: $WORKING_DIR
            run: terraform plan -no-color -out=tfplan
            continue-on-error: true

          - name: Comment Plan on PR
            uses: actions/github-script@v7
            with:
              script: |
                const plan = `${{ steps.plan.outputs.stdout }}`;
                const truncated = plan.length > 65000
                  ? plan.substring(0, 65000) + '\n\n... (truncated)'
                  : plan;

                github.rest.issues.createComment({
                  issue_number: context.issue.number,
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  body: '### Terraform Plan\n```\n' + truncated + '\n```'
                });

          - name: Plan Status
            if: steps.plan.outcome == 'failure'
            run: exit 1

      # ---- APPLY (runs on merge to main) ----
      apply:
        name: Terraform Apply
        runs-on: ubuntu-latest
        if: github.event_name == 'push' && github.ref == 'refs/heads/${var.git_branch}'
        environment: production    # Requires approval

        steps:
          - name: Checkout code
            uses: actions/checkout@v4

          - name: Setup Terraform
            uses: hashicorp/setup-terraform@v3
            with:
              terraform_version: $TF_VERSION

          - name: Terraform Init
            working-directory: $WORKING_DIR
            run: terraform init -no-color

          - name: Terraform Apply
            working-directory: $WORKING_DIR
            run: terraform apply -auto-approve -no-color
  EOT
}

# ========================================================================
# SECTION 2: AZURE DEVOPS PIPELINE
# ========================================================================

resource "local_file" "azure_devops" {
  filename = "./terraform-lab-output/gitops/azure-devops-terraform.yml"
  content  = <<-EOT
    # Azure DevOps: Terraform CI/CD Pipeline
    # ========================================
    # Uses stages for plan -> approve -> apply workflow

    trigger:
      branches:
        include:
          - ${var.git_branch}
      paths:
        include:
          - terraform/*

    pr:
      branches:
        include:
          - ${var.git_branch}
      paths:
        include:
          - terraform/*

    pool:
      vmImage: 'ubuntu-latest'

    variables:
      - name: TF_VERSION
        value: '1.6.0'
      - name: WORKING_DIR
        value: 'terraform'

    stages:
      # ---- VALIDATE ----
      - stage: Validate
        displayName: 'Terraform Validate'
        jobs:
          - job: validate
            steps:
              - task: TerraformInstaller@1
                inputs:
                  terraformVersion: $(TF_VERSION)

              - script: |
                  cd $(WORKING_DIR)
                  terraform init -backend=false
                  terraform validate
                  terraform fmt -check
                displayName: 'Validate and Format Check'

      # ---- PLAN ----
      - stage: Plan
        displayName: 'Terraform Plan'
        dependsOn: Validate
        jobs:
          - job: plan
            steps:
              - task: TerraformInstaller@1
                inputs:
                  terraformVersion: $(TF_VERSION)

              - script: |
                  cd $(WORKING_DIR)
                  terraform init
                  terraform plan -out=tfplan -no-color
                displayName: 'Terraform Plan'

              - publish: $(WORKING_DIR)/tfplan
                artifact: tfplan
                displayName: 'Publish Plan Artifact'

      # ---- APPLY (manual approval gate) ----
      - stage: Apply
        displayName: 'Terraform Apply'
        dependsOn: Plan
        condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/${var.git_branch}'))
        jobs:
          - deployment: apply
            environment: 'production'    # Has approval gate
            strategy:
              runOnce:
                deploy:
                  steps:
                    - task: TerraformInstaller@1
                      inputs:
                        terraformVersion: $(TF_VERSION)

                    - download: current
                      artifact: tfplan

                    - script: |
                        cd $(WORKING_DIR)
                        terraform init
                        terraform apply -auto-approve $(Pipeline.Workspace)/tfplan/tfplan
                      displayName: 'Terraform Apply'
  EOT
}

# ========================================================================
# SECTION 3: GITOPS WORKFLOW DOCUMENTATION
# ========================================================================

resource "local_file" "workflow_guide" {
  filename = "./terraform-lab-output/gitops/gitops-workflow-guide.md"
  content  = <<-EOT
    # GitOps Workflow for Terraform

    ## The Golden Rule
    **All infrastructure changes go through Git. No manual applies.**

    ## Workflow Steps

    ### 1. Create a Branch
    ```bash
    git checkout -b feature/add-new-subnet
    ```

    ### 2. Make Changes
    Edit Terraform files, test locally with `terraform plan`.

    ### 3. Open a Pull Request
    ```bash
    git push -u origin feature/add-new-subnet
    gh pr create --title "Add new subnet for app tier"
    ```

    ### 4. Automated Plan
    CI/CD pipeline runs `terraform plan` and posts the output
    as a PR comment. Reviewers see exactly what will change.

    ### 5. Code Review
    Team reviews:
    - Is the plan output expected?
    - Are there any destructive changes?
    - Does it follow naming conventions?
    - Are costs acceptable?

    ### 6. Merge
    After approval, merge to ${var.git_branch}.

    ### 7. Automated Apply
    Pipeline runs `terraform apply` with the approved plan.
    Infrastructure is updated.

    ### 8. Drift Detection (Scheduled)
    A scheduled pipeline runs `terraform plan` daily.
    If drift is detected, it creates an alert/issue.

    ## Branch Strategy

    ```
    main (protected)
    ├── feature/add-subnet        → PR → plan → review → merge → apply
    ├── feature/update-security   → PR → plan → review → merge → apply
    └── hotfix/fix-sg-rule        → PR → plan → review → merge → apply
    ```

    ## Safety Measures
    1. **Branch protection**: Require PR reviews for main
    2. **Required checks**: Plan must succeed before merge
    3. **Environment gates**: Manual approval before production apply
    4. **Plan artifacts**: Save plan output, apply exact plan
    5. **Drift detection**: Scheduled runs catch manual changes
    6. **Cost estimation**: Infracost integration shows cost impact
  EOT
}

# ========================================================================
# SECTION 4: DRIFT DETECTION
# ========================================================================

resource "local_file" "drift_detection" {
  filename = "./terraform-lab-output/gitops/drift-detection-workflow.yml"
  content  = <<-EOT
    # Drift Detection: Scheduled Pipeline
    # =====================================
    # Runs daily to detect manual changes to infrastructure

    name: Terraform Drift Detection

    on:
      schedule:
        - cron: '0 6 * * *'    # Daily at 6 AM UTC
      workflow_dispatch:         # Manual trigger

    jobs:
      detect-drift:
        name: Detect Infrastructure Drift
        runs-on: ubuntu-latest

        steps:
          - uses: actions/checkout@v4

          - uses: hashicorp/setup-terraform@v3
            with:
              terraform_version: '1.6.0'

          - name: Terraform Init
            run: terraform init -no-color

          - name: Detect Drift
            id: drift
            run: |
              terraform plan -detailed-exitcode -no-color 2>&1 | tee plan_output.txt
              EXIT_CODE=$?
              if [ $EXIT_CODE -eq 2 ]; then
                echo "drift_detected=true" >> $GITHUB_OUTPUT
                echo "DRIFT DETECTED - Infrastructure has changed outside Terraform"
              elif [ $EXIT_CODE -eq 0 ]; then
                echo "drift_detected=false" >> $GITHUB_OUTPUT
                echo "No drift detected - Infrastructure matches configuration"
              else
                echo "Error running terraform plan"
                exit 1
              fi

          - name: Create Issue on Drift
            if: steps.drift.outputs.drift_detected == 'true'
            uses: actions/github-script@v7
            with:
              script: |
                const fs = require('fs');
                const plan = fs.readFileSync('plan_output.txt', 'utf8');
                github.rest.issues.create({
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  title: 'Infrastructure Drift Detected',
                  body: '## Drift Report\n```\n' + plan.slice(0, 60000) + '\n```',
                  labels: ['drift', 'infrastructure']
                });
  EOT
}

# ========================================================================
# SECTION 5: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-gitops.ps1"
  content  = <<-EOT
    # GitOps: Terraform vs PowerShell CI/CD Patterns
    # ================================================

    # TERRAFORM GITOPS               | POWERSHELL CI/CD
    # -------------------------------|-------------------------------
    # terraform plan (on PR)         | Pester tests + What-If
    # terraform apply (on merge)     | Run deployment script
    # Plan output as PR comment      | Test results as PR comment
    # State drift detection          | Scheduled DSC compliance check
    # terraform fmt -check           | PSScriptAnalyzer
    # terraform validate             | Test-DSCConfiguration

    # PowerShell CI/CD equivalent
    # ----------------------------

    # Step 1: Validate (like terraform validate)
    # Invoke-ScriptAnalyzer -Path ./Deploy-Infrastructure.ps1

    # Step 2: Plan/Preview (like terraform plan)
    # New-AzResourceGroupDeployment -WhatIf -TemplateFile main.bicep

    # Step 3: Test (like terraform plan -detailed-exitcode)
    # Invoke-Pester -Path ./tests/ -OutputFormat NUnitXml

    # Step 4: Deploy (like terraform apply)
    # New-AzResourceGroupDeployment -TemplateFile main.bicep

    # Step 5: Drift Detection (like scheduled terraform plan)
    # Test-DscConfiguration -Detailed | Where-Object { -not $$_.InDesiredState }

    Write-Host "GitOps Workflow Comparison:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Terraform GitOps is powerful because:" -ForegroundColor Cyan
    Write-Host "  1. 'terraform plan' shows EXACT changes before they happen"
    Write-Host "  2. Plan output is deterministic and reviewable"
    Write-Host "  3. State tracking enables automatic drift detection"
    Write-Host "  4. Apply is idempotent - safe to re-run"
    Write-Host ""
    Write-Host "  PowerShell CI/CD requires more custom work:" -ForegroundColor Cyan
    Write-Host "  1. -WhatIf support varies by cmdlet"
    Write-Host "  2. Preview output is less structured"
    Write-Host "  3. No built-in drift detection (need DSC or custom scripts)"
    Write-Host "  4. Must handle idempotency yourself"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "generated_files" {
  description = "Generated pipeline and workflow files"
  value = {
    github_actions  = local_file.github_actions.filename
    azure_devops    = local_file.azure_devops.filename
    workflow_guide  = local_file.workflow_guide.filename
    drift_detection = local_file.drift_detection.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    golden_rule     = "All infrastructure changes go through Git pull requests"
    plan_on_pr      = "CI runs 'terraform plan' on every PR for review"
    apply_on_merge  = "CI runs 'terraform apply' after merge to main"
    drift_detection = "Scheduled pipelines detect manual infrastructure changes"
    safety          = "Branch protection + required checks + approval gates"
    platforms       = "GitHub Actions and Azure DevOps both support Terraform workflows"
  }
}
