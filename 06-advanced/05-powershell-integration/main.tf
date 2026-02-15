# ╔════════════════════════════════════════════════════════════════════╗
# ║  POWERSHELL AND TERRAFORM INTEGRATION                           ║
# ║  Bridging your PowerShell expertise with Terraform              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise demonstrates how to use PowerShell and Terraform together:
# provisioners for running scripts, external data sources for dynamic values,
# consuming Terraform outputs in PowerShell automation, and building hybrid
# workflows that leverage the strengths of both tools.

# This is the CAPSTONE exercise for PowerShell administrators learning
# Terraform. It shows you how to combine what you know with what you've
# learned throughout this lab series.

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
  default     = "terraform-ps-integration"
}

variable "environment" {
  description = "Target environment"
  type        = string
  default     = "development"
}

variable "servers" {
  description = "Server configurations"
  type = map(object({
    role = string
    ip   = string
    os   = string
  }))
  default = {
    web01 = { role = "webserver", ip = "10.0.1.10", os = "Windows Server 2022" }
    db01  = { role = "database",  ip = "10.0.1.20", os = "Windows Server 2022" }
    app01 = { role = "appserver", ip = "10.0.1.30", os = "Windows Server 2022" }
  }
}

# ========================================================================
# SECTION 1: LOCAL-EXEC PROVISIONER WITH POWERSHELL
# ========================================================================

resource "local_file" "provisioner_examples" {
  filename = "./terraform-lab-output/ps-integration/local-exec-provisioner.tf"
  content  = <<-EOT
    # ============================================
    # LOCAL-EXEC PROVISIONER WITH POWERSHELL
    # ============================================
    # Run PowerShell scripts as part of Terraform apply.
    # Use sparingly - provisioners are a last resort!

    # --- Example 1: Simple PowerShell command ---
    resource "null_resource" "run_powershell" {
      provisioner "local-exec" {
        command     = "Write-Host 'Terraform just created resources!'"
        interpreter = ["PowerShell", "-Command"]
      }
    }

    # --- Example 2: Run a PowerShell script file ---
    resource "null_resource" "run_script" {
      provisioner "local-exec" {
        command     = "$${path.module}/scripts/Post-Deploy.ps1 -Environment '${var.environment}'"
        interpreter = ["PowerShell", "-File"]
      }

      # Re-run if environment changes
      triggers = {
        environment = var.environment
      }
    }

    # --- Example 3: Cleanup on destroy ---
    resource "null_resource" "cleanup" {
      provisioner "local-exec" {
        when        = destroy
        command     = "Write-Host 'Running cleanup before destroy...'"
        interpreter = ["PowerShell", "-Command"]
      }
    }

    # --- Example 4: Remote PowerShell (WinRM) ---
    resource "null_resource" "configure_remote" {
      connection {
        type     = "winrm"
        host     = "server.example.com"
        user     = "Administrator"
        password = var.admin_password
        https    = true
        insecure = false
      }

      provisioner "remote-exec" {
        inline = [
          "Install-WindowsFeature Web-Server -IncludeManagementTools",
          "New-Website -Name 'MyApp' -Port 80 -PhysicalPath 'C:\\inetpub\\wwwroot'",
        ]
      }
    }

    # IMPORTANT: Provisioners should be a last resort!
    # Prefer: native Terraform resources, user_data, or configuration management tools
  EOT
}

# ========================================================================
# SECTION 2: EXTERNAL DATA SOURCE (POWERSHELL -> TERRAFORM)
# ========================================================================

resource "local_file" "external_data" {
  filename = "./terraform-lab-output/ps-integration/external-data-source.tf"
  content  = <<-EOT
    # ============================================
    # EXTERNAL DATA SOURCE WITH POWERSHELL
    # ============================================
    # Use PowerShell to feed dynamic values INTO Terraform.
    # The script must output JSON to stdout.

    # --- Example 1: Get current user info ---
    data "external" "current_user" {
      program = ["PowerShell", "-Command", <<-PS
        $$result = @{
          username    = $$env:USERNAME
          computer    = $$env:COMPUTERNAME
          domain      = $$env:USERDOMAIN
          home_dir    = $$env:USERPROFILE
        } | ConvertTo-Json -Compress
        Write-Output $$result
      PS
      ]
    }

    output "current_user" {
      value = data.external.current_user.result
    }

    # --- Example 2: Query Active Directory ---
    data "external" "ad_info" {
      program = ["PowerShell", "-File", "$${path.module}/scripts/Get-ADInfo.ps1"]

      query = {
        ou_path    = "OU=Servers,DC=lab,DC=local"
        filter     = "enabled"
      }
    }

    # --- Example 3: Get available disk space ---
    data "external" "disk_space" {
      program = ["PowerShell", "-Command", <<-PS
        $$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" |
          Select-Object @{N='free_gb';E={[math]::Round($$_.FreeSpace/1GB,2)}},
                       @{N='total_gb';E={[math]::Round($$_.Size/1GB,2)}}
        @{
          free_gb  = $$disk.free_gb.ToString()
          total_gb = $$disk.total_gb.ToString()
        } | ConvertTo-Json -Compress | Write-Output
      PS
      ]
    }

    # RULES for external data sources:
    # 1. Script must output valid JSON to stdout
    # 2. All values must be strings (even numbers)
    # 3. Script receives query as JSON on stdin
    # 4. Exit code 0 = success, non-zero = error
    # 5. Stderr is shown as error messages
  EOT
}

# ========================================================================
# SECTION 3: CONSUMING TERRAFORM OUTPUTS IN POWERSHELL
# ========================================================================

resource "local_file" "output_consumer" {
  filename = "./terraform-lab-output/ps-integration/Consume-TerraformOutputs.ps1"
  content  = <<-EOT
    #Requires -Version 5.1
    <#
    .SYNOPSIS
        Consume Terraform outputs in PowerShell automation
    .DESCRIPTION
        Shows multiple patterns for reading Terraform outputs
        and using them in PowerShell scripts.
    .EXAMPLE
        .\Consume-TerraformOutputs.ps1 -TerraformDir "C:\infra\production"
    #>
    param(
        [string]$$TerraformDir = ".",
        [string]$$Environment = "${var.environment}"
    )

    # ============================================
    # PATTERN 1: Read all outputs as JSON
    # ============================================
    Write-Host "Reading Terraform outputs..." -ForegroundColor Yellow

    Push-Location $$TerraformDir
    try {
        $$outputs = terraform output -json | ConvertFrom-Json

        # Access specific outputs
        $$serverIPs = $$outputs.server_ips.value
        $$vpcId     = $$outputs.vpc_id.value
        $$dbEndpoint = $$outputs.database_endpoint.value

        Write-Host "VPC ID: $$vpcId"
        Write-Host "DB Endpoint: $$dbEndpoint"
    } finally {
        Pop-Location
    }

    # ============================================
    # PATTERN 2: Read specific output
    # ============================================
    $$lbDns = terraform output -raw load_balancer_dns
    Write-Host "Load Balancer: $$lbDns"

    # ============================================
    # PATTERN 3: Use outputs for server configuration
    # ============================================
    $$servers = $$outputs.server_configs.value

    foreach ($$server in $$servers.PSObject.Properties) {
        $$config = $$server.Value
        Write-Host "`nConfiguring $$($server.Name)..." -ForegroundColor Cyan

        # Configure IIS on web servers
        if ($$config.role -eq "webserver") {
            # Invoke-Command -ComputerName $$config.ip -ScriptBlock {
            #     Install-WindowsFeature Web-Server
            #     New-Website -Name "MyApp" -Port 80
            # }
            Write-Host "  Would configure IIS on $$($config.ip)"
        }

        # Configure SQL on database servers
        if ($$config.role -eq "database") {
            # Invoke-Command -ComputerName $$config.ip -ScriptBlock {
            #     Install-WindowsFeature SQL-Server-2022
            # }
            Write-Host "  Would configure SQL on $$($config.ip)"
        }
    }

    # ============================================
    # PATTERN 4: Generate reports from Terraform state
    # ============================================
    function Get-TerraformInventory {
        param([string]$$StateDir = ".")

        Push-Location $$StateDir
        try {
            $$stateJson = terraform show -json | ConvertFrom-Json
            $$resources = $$stateJson.values.root_module.resources

            $$resources | ForEach-Object {
                [PSCustomObject]@{
                    Type    = $$_.type
                    Name    = $$_.name
                    Address = $$_.address
                    Values  = $$_.values
                }
            }
        } finally {
            Pop-Location
        }
    }

    # Usage:
    # Get-TerraformInventory | Format-Table Type, Name, Address
    # Get-TerraformInventory | Where-Object Type -eq "aws_instance" | Select-Object -ExpandProperty Values

    Write-Host "`nIntegration patterns demonstrated!" -ForegroundColor Green
  EOT
}

# ========================================================================
# SECTION 4: HYBRID WORKFLOW SCRIPTS
# ========================================================================

resource "local_file" "hybrid_workflow" {
  filename = "./terraform-lab-output/ps-integration/Deploy-HybridWorkflow.ps1"
  content  = <<-EOT
    #Requires -Version 5.1
    <#
    .SYNOPSIS
        Hybrid Terraform + PowerShell deployment workflow
    .DESCRIPTION
        Demonstrates a production deployment pattern that uses Terraform
        for infrastructure and PowerShell for configuration management.
    #>
    param(
        [ValidateSet("development", "staging", "production")]
        [string]$$Environment = "${var.environment}",
        [switch]$$PlanOnly,
        [switch]$$AutoApprove
    )

    $$ErrorActionPreference = "Stop"

    # ============================================
    # STEP 1: Pre-flight checks (PowerShell)
    # ============================================
    Write-Host "=== Step 1: Pre-flight Checks ===" -ForegroundColor Yellow

    # Verify Terraform is installed
    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
        throw "Terraform is not installed. Run: choco install terraform"
    }

    # Verify we're in the right directory
    if (-not (Test-Path "main.tf")) {
        throw "No main.tf found. Are you in the right directory?"
    }

    # Check environment credentials
    $$requiredVars = @("AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY")
    foreach ($$var in $$requiredVars) {
        if (-not [Environment]::GetEnvironmentVariable($$var)) {
            Write-Warning "Missing env var: $$var"
        }
    }

    Write-Host "  Pre-flight checks passed" -ForegroundColor Green

    # ============================================
    # STEP 2: Terraform workspace setup
    # ============================================
    Write-Host "`n=== Step 2: Workspace Setup ===" -ForegroundColor Yellow

    terraform workspace select $$Environment 2>$$null
    if ($$LASTEXITCODE -ne 0) {
        Write-Host "  Creating workspace: $$Environment"
        terraform workspace new $$Environment
    }
    Write-Host "  Workspace: $$(terraform workspace show)"

    # ============================================
    # STEP 3: Terraform init and plan
    # ============================================
    Write-Host "`n=== Step 3: Terraform Init & Plan ===" -ForegroundColor Yellow

    terraform init -no-color
    if ($$LASTEXITCODE -ne 0) { throw "terraform init failed" }

    terraform plan -no-color -out="$$Environment.tfplan"
    if ($$LASTEXITCODE -ne 0) { throw "terraform plan failed" }

    if ($$PlanOnly) {
        Write-Host "Plan-only mode. Review the plan above." -ForegroundColor Cyan
        return
    }

    # ============================================
    # STEP 4: Terraform apply
    # ============================================
    Write-Host "`n=== Step 4: Terraform Apply ===" -ForegroundColor Yellow

    if (-not $$AutoApprove) {
        $$confirm = Read-Host "Apply changes to $$Environment? (yes/no)"
        if ($$confirm -ne "yes") {
            Write-Host "Aborted." -ForegroundColor Red
            return
        }
    }

    terraform apply "$$Environment.tfplan"
    if ($$LASTEXITCODE -ne 0) { throw "terraform apply failed" }

    # ============================================
    # STEP 5: Post-deployment (PowerShell)
    # ============================================
    Write-Host "`n=== Step 5: Post-Deployment ===" -ForegroundColor Yellow

    # Read outputs
    $$outputs = terraform output -json | ConvertFrom-Json

    # Run post-deployment validation
    Write-Host "  Validating deployment..."
    # Test-NetConnection -ComputerName $$outputs.lb_dns.value -Port 443

    # Send notification
    Write-Host "  Deployment to $$Environment complete!" -ForegroundColor Green

    # Clean up plan file
    Remove-Item "$$Environment.tfplan" -ErrorAction SilentlyContinue
  EOT
}

# ========================================================================
# SECTION 5: INTEGRATION PATTERNS SUMMARY
# ========================================================================

resource "local_file" "patterns_summary" {
  filename = "./terraform-lab-output/ps-integration/integration-patterns.json"
  content = jsonencode({
    title = "PowerShell + Terraform Integration Patterns"
    patterns = {
      "ps_to_terraform" = {
        name        = "PowerShell feeds data TO Terraform"
        mechanism   = "external data source"
        use_case    = "Query AD, read registry, check system state"
        example     = "data \"external\" \"info\" { program = [\"PowerShell\", ...] }"
      }
      "terraform_to_ps" = {
        name        = "Terraform outputs consumed BY PowerShell"
        mechanism   = "terraform output -json | ConvertFrom-Json"
        use_case    = "Post-deployment configuration, reporting, validation"
        example     = "$outputs = terraform output -json | ConvertFrom-Json"
      }
      "ps_provisioner" = {
        name        = "PowerShell runs DURING Terraform apply"
        mechanism   = "local-exec provisioner with PowerShell interpreter"
        use_case    = "Post-creation scripts, notifications, custom setup"
        example     = "provisioner \"local-exec\" { interpreter = [\"PowerShell\", \"-Command\"] }"
      }
      "hybrid_workflow" = {
        name        = "PowerShell orchestrates Terraform"
        mechanism   = "PowerShell wrapper script calling terraform CLI"
        use_case    = "Deployment pipelines, environment management"
        example     = "Deploy-Infrastructure.ps1 -Environment production"
      }
      "winrm_remote" = {
        name        = "Terraform configures remote Windows servers"
        mechanism   = "remote-exec provisioner with WinRM connection"
        use_case    = "Server configuration after creation"
        example     = "connection { type = \"winrm\" }"
      }
    }
    best_practices = [
      "Use Terraform for infrastructure, PowerShell for configuration",
      "Prefer native Terraform resources over provisioners",
      "Use external data sources sparingly (they run on every plan)",
      "Always output structured data (JSON) for cross-tool integration",
      "Wrap Terraform in PowerShell for deployment pipelines"
    ]
  })
}

# ========================================================================
# SECTION 6: SERVER CONFIG GENERATION
# ========================================================================

# Generate server-specific PowerShell configs from Terraform variables
resource "local_file" "server_configs" {
  for_each = var.servers

  filename = "./terraform-lab-output/ps-integration/configs/${each.key}-config.ps1"
  content  = <<-EOT
    # Auto-generated by Terraform for ${each.key}
    # Role: ${each.value.role}
    # OS: ${each.value.os}

    $$ServerConfig = @{
        Name        = "${each.key}"
        Role        = "${each.value.role}"
        IPAddress   = "${each.value.ip}"
        OS          = "${each.value.os}"
        Environment = "${var.environment}"
        Project     = "${var.project_name}"
    }

    Write-Host "Configuring $$($$ServerConfig.Name) as $$($$ServerConfig.Role)..."
    # Apply role-specific configuration here
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "generated_files" {
  description = "Generated integration files"
  value = {
    provisioner_examples = local_file.provisioner_examples.filename
    external_data        = local_file.external_data.filename
    output_consumer      = local_file.output_consumer.filename
    hybrid_workflow      = local_file.hybrid_workflow.filename
    patterns_summary     = local_file.patterns_summary.filename
  }
}

output "server_configs" {
  description = "Generated server config paths"
  value = { for k, v in local_file.server_configs : k => v.filename }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    provisioners    = "Use local-exec with PowerShell interpreter for post-deploy scripts"
    external_data   = "Feed PowerShell query results into Terraform via external data sources"
    output_consumption = "Read Terraform outputs with 'terraform output -json | ConvertFrom-Json'"
    hybrid_workflow = "Wrap Terraform in PowerShell scripts for deployment pipelines"
    best_practice   = "Terraform for infrastructure, PowerShell for configuration management"
    capstone        = "This exercise ties together everything in the lab series"
  }
}
