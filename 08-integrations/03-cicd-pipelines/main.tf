# ╔════════════════════════════════════════════════════════════════════╗
# ║  CI/CD PIPELINE INTEGRATION                                     ║
# ║  Running Terraform in automated pipelines                       ║
# ╚════════════════════════════════════════════════════════════════════╝

# Terraform in CI/CD is where infrastructure as code truly shines.
# Automated pipelines ensure consistent applies, enforce reviews,
# and prevent manual mistakes. This exercise generates complete
# pipeline configurations for GitHub Actions, Azure DevOps, and GitLab.

# POWERSHELL COMPARISON:
# =====================
# Like PowerShell scripts in Azure DevOps tasks, but with built-in
# plan-approve-apply workflow:
#   PS pipeline: task: PowerShell; script: ./deploy.ps1
#   TF pipeline: terraform plan -> review -> terraform apply

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
  description = "Project/repository name"
  type        = string
  default     = "infrastructure"
}

variable "environments" {
  description = "Deployment environments"
  type        = list(string)
  default     = ["dev", "staging", "production"]
}

variable "terraform_version" {
  description = "Terraform version for CI"
  type        = string
  default     = "1.6.0"
}

# ========================================================================
# SECTION 1: GITHUB ACTIONS PIPELINE
# ========================================================================

resource "local_file" "github_actions" {
  filename = "./terraform-lab-output/cicd-pipelines/github-actions-terraform.yml"
  content  = <<-EOT
    # GitHub Actions: Terraform CI/CD Pipeline
    # ==========================================
    # Plan on PR, apply on merge to main

    name: "Terraform"

    on:
      push:
        branches: [main]
        paths: ['terraform/**']
      pull_request:
        branches: [main]
        paths: ['terraform/**']

    permissions:
      contents: read
      pull-requests: write  # For PR comments

    env:
      TF_VERSION: "${var.terraform_version}"
      TF_WORKING_DIR: "terraform"
      # Credentials (set in GitHub Secrets)
      # AWS_ACCESS_KEY_ID: $${{ secrets.AWS_ACCESS_KEY_ID }}
      # AWS_SECRET_ACCESS_KEY: $${{ secrets.AWS_SECRET_ACCESS_KEY }}
      # ARM_CLIENT_ID: $${{ secrets.AZURE_CLIENT_ID }}

    jobs:
      # --- Validate & Plan ---
      plan:
        name: "Terraform Plan"
        runs-on: ubuntu-latest
        steps:
          - name: Checkout
            uses: actions/checkout@v4

          - name: Setup Terraform
            uses: hashicorp/setup-terraform@v3
            with:
              terraform_version: $${{ env.TF_VERSION }}

          - name: Terraform Init
            working-directory: $${{ env.TF_WORKING_DIR }}
            run: terraform init -backend-config="backend.hcl"

          - name: Terraform Format Check
            working-directory: $${{ env.TF_WORKING_DIR }}
            run: terraform fmt -check -recursive

          - name: Terraform Validate
            working-directory: $${{ env.TF_WORKING_DIR }}
            run: terraform validate

          - name: Terraform Plan
            id: plan
            working-directory: $${{ env.TF_WORKING_DIR }}
            run: terraform plan -no-color -out=tfplan
            continue-on-error: true

          - name: Comment PR with Plan
            uses: actions/github-script@v7
            if: github.event_name == 'pull_request'
            with:
              script: |
                const output = `#### Terraform Plan
                \`\`\`
                $${{ steps.plan.outputs.stdout }}
                \`\`\`
                *Pushed by: @$${{ github.actor }}*`;
                github.rest.issues.createComment({
                  issue_number: context.issue.number,
                  owner: context.repo.owner,
                  repo: context.repo.repo,
                  body: output
                })

          - name: Upload Plan Artifact
            uses: actions/upload-artifact@v4
            with:
              name: tfplan
              path: $${{ env.TF_WORKING_DIR }}/tfplan

      # --- Apply (only on main branch merge) ---
      apply:
        name: "Terraform Apply"
        needs: plan
        runs-on: ubuntu-latest
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        environment: production  # Requires manual approval
        steps:
          - name: Checkout
            uses: actions/checkout@v4

          - name: Setup Terraform
            uses: hashicorp/setup-terraform@v3
            with:
              terraform_version: $${{ env.TF_VERSION }}

          - name: Download Plan
            uses: actions/download-artifact@v4
            with:
              name: tfplan
              path: $${{ env.TF_WORKING_DIR }}

          - name: Terraform Init
            working-directory: $${{ env.TF_WORKING_DIR }}
            run: terraform init -backend-config="backend.hcl"

          - name: Terraform Apply
            working-directory: $${{ env.TF_WORKING_DIR }}
            run: terraform apply -auto-approve tfplan
  EOT
}

# ========================================================================
# SECTION 2: AZURE DEVOPS PIPELINE
# ========================================================================

resource "local_file" "azure_devops" {
  filename = "./terraform-lab-output/cicd-pipelines/azure-devops-terraform.yml"
  content  = <<-EOT
    # Azure DevOps: Terraform CI/CD Pipeline
    # ========================================

    trigger:
      branches:
        include: [main]
      paths:
        include: [terraform/*]

    pr:
      branches:
        include: [main]
      paths:
        include: [terraform/*]

    variables:
      terraformVersion: '${var.terraform_version}'
      workingDirectory: 'terraform'
      # Service connection name for Azure
      azureServiceConnection: 'azure-terraform-sp'

    stages:
    # --- Validate Stage ---
    - stage: Validate
      displayName: 'Validate Terraform'
      jobs:
      - job: Validate
        pool:
          vmImage: 'ubuntu-latest'
        steps:
        - task: TerraformInstaller@1
          inputs:
            terraformVersion: $$(terraformVersion)

        - task: TerraformTaskV4@4
          displayName: 'Terraform Init'
          inputs:
            provider: 'azurerm'
            command: 'init'
            workingDirectory: $$(workingDirectory)
            backendServiceArm: $$(azureServiceConnection)
            backendAzureRmResourceGroupName: 'tfstate-rg'
            backendAzureRmStorageAccountName: 'tfstatestorage'
            backendAzureRmContainerName: 'tfstate'
            backendAzureRmKey: '$(Build.Repository.Name).tfstate'

        - task: TerraformTaskV4@4
          displayName: 'Terraform Validate'
          inputs:
            provider: 'azurerm'
            command: 'validate'
            workingDirectory: $$(workingDirectory)

    # --- Plan Stage ---
    - stage: Plan
      displayName: 'Terraform Plan'
      dependsOn: Validate
      jobs:
      - job: Plan
        pool:
          vmImage: 'ubuntu-latest'
        steps:
        - task: TerraformInstaller@1
          inputs:
            terraformVersion: $$(terraformVersion)

        - task: TerraformTaskV4@4
          displayName: 'Terraform Init'
          inputs:
            provider: 'azurerm'
            command: 'init'
            workingDirectory: $$(workingDirectory)
            backendServiceArm: $$(azureServiceConnection)

        - task: TerraformTaskV4@4
          displayName: 'Terraform Plan'
          inputs:
            provider: 'azurerm'
            command: 'plan'
            workingDirectory: $$(workingDirectory)
            environmentServiceNameAzureRM: $$(azureServiceConnection)
            commandOptions: '-out=tfplan'

        - task: PublishBuildArtifacts@1
          inputs:
            pathToPublish: '$$(workingDirectory)/tfplan'
            artifactName: 'tfplan'

    # --- Apply Stage (manual approval) ---
    - stage: Apply
      displayName: 'Terraform Apply'
      dependsOn: Plan
      condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
      jobs:
      - deployment: Apply
        pool:
          vmImage: 'ubuntu-latest'
        environment: 'production'  # Has approval gates
        strategy:
          runOnce:
            deploy:
              steps:
              - task: TerraformInstaller@1
                inputs:
                  terraformVersion: $$(terraformVersion)

              - task: TerraformTaskV4@4
                displayName: 'Terraform Apply'
                inputs:
                  provider: 'azurerm'
                  command: 'apply'
                  workingDirectory: $$(workingDirectory)
                  environmentServiceNameAzureRM: $$(azureServiceConnection)
                  commandOptions: 'tfplan'
  EOT
}

# ========================================================================
# SECTION 3: CI/CD BEST PRACTICES
# ========================================================================

resource "local_file" "best_practices" {
  filename = "./terraform-lab-output/cicd-pipelines/cicd-best-practices.json"
  content = jsonencode({
    title = "Terraform CI/CD Best Practices"
    practices = {
      plan_on_pr = {
        description = "Always run terraform plan on pull requests"
        why         = "Catch issues before they reach main branch"
        implementation = "Comment plan output on the PR for review"
      }
      apply_on_merge = {
        description = "Only terraform apply after PR merge to main"
        why         = "Ensure reviewed changes are what gets applied"
        implementation = "Use saved plan file from PR for the apply"
      }
      manual_approval = {
        description = "Require manual approval for production applies"
        why         = "Human verification before production changes"
        implementation = "GitHub Environments, Azure DevOps Approvals, GitLab Protected Environments"
      }
      lock_state = {
        description = "Use remote state with locking"
        why         = "Prevent concurrent applies from corrupting state"
        implementation = "S3 + DynamoDB, Azure Storage, GCS backends"
      }
      pin_versions = {
        description = "Pin Terraform and provider versions"
        why         = "Reproducible builds, no surprise upgrades"
        implementation = "required_version = '>= 1.6.0, < 2.0.0' + provider version constraints"
      }
      separate_environments = {
        description = "Use separate state per environment"
        why         = "Isolate blast radius, enable independent deployments"
        implementation = "Workspaces or separate backend configs per env"
      }
      cost_estimation = {
        description = "Add Infracost to the pipeline"
        why         = "See cost impact of changes before approval"
        implementation = "infracost diff as PR comment"
      }
    }
    anti_patterns = [
      "Running terraform apply locally for production",
      "Sharing credentials via environment variables in code",
      "Skipping terraform plan review",
      "Using -auto-approve without saved plan file",
      "Running multiple applies concurrently without locking"
    ]
  })
}

# ========================================================================
# SECTION 4: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-cicd.ps1"
  content  = <<-EOT
    # CI/CD Pipelines: Terraform vs PowerShell Deployments
    # =====================================================

    # TERRAFORM CI/CD                  | POWERSHELL CI/CD
    # ---------------------------------|-------------------------------
    # terraform plan (preview)         | -WhatIf / dry-run flag
    # terraform apply (execute)        | Invoke-Command / ./deploy.ps1
    # Plan saved as artifact           | Script output in logs
    # State locks concurrent runs      | Manual coordination needed
    # Built-in format/validate         | PSScriptAnalyzer / Pester
    # Infracost for cost estimates     | Get-AzConsumptionUsageDetail

    # PowerShell deployment pipeline pattern:
    # stages:
    # - stage: Validate
    #   steps:
    #   - PowerShell: Invoke-ScriptAnalyzer -Path ./scripts
    #   - PowerShell: Invoke-Pester -Path ./tests
    #
    # - stage: Deploy
    #   steps:
    #   - PowerShell: ./Deploy-Infrastructure.ps1 -Environment prod -WhatIf
    #   - ManualValidation: Approve deployment
    #   - PowerShell: ./Deploy-Infrastructure.ps1 -Environment prod

    Write-Host "CI/CD Pipeline Patterns:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Terraform Pipeline:" -ForegroundColor Cyan
    Write-Host "    PR:    fmt check -> validate -> plan -> PR comment"
    Write-Host "    Merge: init -> plan -> approve -> apply"
    Write-Host ""
    Write-Host "  PowerShell Pipeline:" -ForegroundColor Green
    Write-Host "    PR:    PSScriptAnalyzer -> Pester tests"
    Write-Host "    Merge: Script -> -WhatIf -> approve -> execute"
    Write-Host ""
    Write-Host "  Key Insight:" -ForegroundColor Magenta
    Write-Host "    Terraform's plan/apply workflow was DESIGNED for CI/CD"
    Write-Host "    PowerShell scripts need manual -WhatIf implementation"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "cicd_resources" {
  description = "Generated CI/CD pipeline files"
  value = {
    github_actions = local_file.github_actions.filename
    azure_devops   = local_file.azure_devops.filename
    best_practices = local_file.best_practices.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    plan_on_pr      = "Always run terraform plan on PRs and comment the output"
    apply_on_merge  = "Only apply after PR merge to main, using the saved plan"
    manual_approval = "Require human approval for production applies"
    state_locking   = "Use remote state with locking to prevent concurrent applies"
    pin_versions    = "Pin Terraform and provider versions for reproducible builds"
    never_local     = "Never run terraform apply locally for production environments"
  }
}
