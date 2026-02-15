# ╔════════════════════════════════════════════════════════════════════╗
# ║  COST OPTIMIZATION STRATEGIES                                    ║
# ║  Control cloud spending with Terraform patterns                 ║
# ╚════════════════════════════════════════════════════════════════════╝

# Infrastructure as code gives you powerful tools for cost control:
# right-sizing resources, scheduling shutdowns, using spot instances,
# and estimating costs before deployment. This exercise demonstrates
# cost-aware Terraform patterns.

# POWERSHELL COMPARISON:
# =====================
# Like PowerShell scripts that audit and right-size cloud resources:
#   Get-AzVM | Where-Object { $_.HardwareProfile.VmSize -eq "Standard_D4s_v3" }
# Terraform embeds cost awareness directly in the provisioning workflow.

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

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "enable_cost_saving" {
  description = "Enable cost-saving measures"
  type        = bool
  default     = true
}

# ========================================================================
# SECTION 1: RIGHT-SIZING PATTERNS
# ========================================================================

locals {
  # Environment-based right-sizing
  instance_sizes = {
    development = {
      web    = "t3.micro"
      app    = "t3.small"
      db     = "db.t3.micro"
      cache  = "cache.t3.micro"
      cost   = "~$30/month"
    }
    staging = {
      web    = "t3.small"
      app    = "t3.medium"
      db     = "db.t3.small"
      cache  = "cache.t3.small"
      cost   = "~$120/month"
    }
    production = {
      web    = "t3.large"
      app    = "t3.xlarge"
      db     = "db.r5.large"
      cache  = "cache.r5.large"
      cost   = "~$800/month"
    }
  }

  current_sizes = local.instance_sizes[var.environment]
}

resource "local_file" "rightsizing_guide" {
  filename = "./terraform-lab-output/cost-optimization/right-sizing-guide.json"
  content = jsonencode({
    title       = "Environment-Based Right-Sizing"
    environment = var.environment
    sizes       = local.current_sizes
    all_environments = local.instance_sizes
    patterns = {
      workspace_sizing = "Use terraform.workspace to select instance sizes per env"
      variable_sizing  = "Pass instance_type as a variable per environment"
      map_lookup       = "Use lookup() with environment-keyed maps"
    }
    savings_tips = [
      "Dev environments should use smallest instances possible",
      "Use burstable instances (t3/t4g) for intermittent workloads",
      "Consider ARM-based instances (t4g) for 20% cost savings",
      "Right-size databases - most are over-provisioned",
      "Use reserved instances or savings plans for steady-state production"
    ]
  })
}

# ========================================================================
# SECTION 2: COST ESTIMATION TOOLS
# ========================================================================

resource "local_file" "cost_estimation" {
  filename = "./terraform-lab-output/cost-optimization/cost-estimation-tools.md"
  content  = <<-EOT
    # Terraform Cost Estimation Tools

    ## 1. Infracost (Recommended)
    ```bash
    # Install
    # Windows: choco install infracost
    # macOS: brew install infracost

    # Get cost estimate for current config
    infracost breakdown --path .

    # Compare costs between branches
    infracost diff --path .

    # Add to CI/CD (PR comment with cost impact)
    infracost comment github --path . \
      --repo my-org/my-repo \
      --pull-request 123
    ```

    Example output:
    ```
    Name                              Monthly Qty  Unit    Monthly Cost
    aws_instance.web
    ├─ Instance usage (t3.large)          730  hours        $60.74
    ├─ root_block_device - GP3            30  GB             $2.40
    └─ CPU credits                         0  vCPU-hours     $0.00

    aws_db_instance.main
    ├─ Database instance (db.r5.large)   730  hours        $172.80
    └─ Storage (gp2)                     100  GB            $11.50

    OVERALL TOTAL                                          $247.44
    ```

    ## 2. Terraform Cloud Cost Estimation
    Built into Terraform Cloud/Enterprise.
    Shows estimated monthly cost in plan output.

    ## 3. AWS Cost Calculator
    ```bash
    # Use AWS Pricing API
    aws pricing get-products --service-code AmazonEC2 \
      --filters Type=TERM_MATCH,Field=instanceType,Value=t3.large
    ```

    ## 4. terraform plan + Manual Review
    Always review `terraform plan` output for:
    - Number of resources being created
    - Instance sizes and types
    - Storage volumes and sizes
    - Data transfer implications
  EOT
}

# ========================================================================
# SECTION 3: COST-SAVING PATTERNS
# ========================================================================

resource "local_file" "cost_patterns" {
  filename = "./terraform-lab-output/cost-optimization/cost-saving-patterns.tf"
  content  = <<-EOT
    # ============================================
    # COST-SAVING TERRAFORM PATTERNS
    # ============================================

    # --- Pattern 1: Scheduled start/stop for non-prod ---
    # Save 65% by stopping dev instances at night and weekends
    resource "aws_autoscaling_schedule" "scale_down_night" {
      scheduled_action_name  = "scale-down-night"
      min_size               = 0
      max_size               = 0
      desired_capacity       = 0
      recurrence             = "0 18 * * MON-FRI"  # 6 PM weekdays
      autoscaling_group_name = aws_autoscaling_group.dev.name
    }

    resource "aws_autoscaling_schedule" "scale_up_morning" {
      scheduled_action_name  = "scale-up-morning"
      min_size               = 1
      max_size               = 3
      desired_capacity       = 1
      recurrence             = "0 8 * * MON-FRI"   # 8 AM weekdays
      autoscaling_group_name = aws_autoscaling_group.dev.name
    }

    # --- Pattern 2: Spot instances for non-critical workloads ---
    resource "aws_spot_instance_request" "worker" {
      ami                    = "ami-12345678"
      instance_type          = "t3.large"
      spot_price             = "0.05"  # Max bid
      wait_for_fulfillment   = true
      spot_type              = "one-time"
    }

    # --- Pattern 3: Lifecycle policies for old resources ---
    resource "aws_s3_bucket_lifecycle_configuration" "logs" {
      bucket = aws_s3_bucket.logs.id

      rule {
        id     = "archive-old-logs"
        status = "Enabled"

        transition {
          days          = 30
          storage_class = "STANDARD_IA"   # 45% cheaper
        }

        transition {
          days          = 90
          storage_class = "GLACIER"        # 80% cheaper
        }

        expiration {
          days = 365  # Delete after 1 year
        }
      }
    }

    # --- Pattern 4: Conditional resources per environment ---
    resource "aws_cloudwatch_log_group" "detailed" {
      count = var.environment == "production" ? 1 : 0
      name  = "/app/detailed-logs"
      retention_in_days = 30  # Don't keep forever!
    }

    # --- Pattern 5: Reserved capacity for steady-state ---
    # resource "aws_ec2_capacity_reservation" "prod" {
    #   instance_type           = "t3.large"
    #   instance_count          = 3
    #   availability_zone       = "us-east-1a"
    #   instance_platform       = "Linux/UNIX"
    #   # 30-70% savings vs on-demand
    # }
  EOT
}

# ========================================================================
# SECTION 4: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-cost-optimization.ps1"
  content  = <<-EOT
    # Cost Optimization: Terraform vs PowerShell Approaches
    # ======================================================

    # TERRAFORM                        | POWERSHELL
    # ---------------------------------|-------------------------------
    # Right-sizing in config           | Get-AzVM | Resize-AzVM
    # Scheduled scaling                | Azure Automation runbooks
    # Spot instances in config         | Request spot via AWS SDK
    # Infracost estimation             | Get-AzConsumptionUsageDetail
    # Lifecycle policies               | Set-AzStorageAccount lifecycle

    # PowerShell: Cloud cost management scripts

    # Get current spending
    # Get-AzConsumptionUsageDetail -StartDate (Get-Date).AddDays(-30) |
    #   Group-Object ResourceType |
    #   Sort-Object Count -Descending |
    #   Select-Object Name, Count, @{N='Cost';E={($_.Group | Measure-Object PretaxCost -Sum).Sum}}

    # Find oversized VMs
    # Get-AzVM | ForEach-Object {
    #   $$metrics = Get-AzMetric -ResourceId $$_.Id -MetricName "Percentage CPU"
    #   if ($$metrics.Data[-1].Average -lt 10) {
    #     Write-Warning "$$($_.Name) is underutilized (CPU < 10%)"
    #   }
    # }

    # Stop dev VMs at night
    # Get-AzVM -ResourceGroupName "dev" | Stop-AzVM -Force

    Write-Host "Cost Optimization Comparison:" -ForegroundColor Yellow
    Write-Host "  Terraform: Cost control BUILT INTO provisioning"
    Write-Host "  PowerShell: Cost control as separate scripts/runbooks"
    Write-Host ""
    Write-Host "  Terraform advantage: Can estimate costs BEFORE deploying"
    Write-Host "  PowerShell advantage: Can analyze EXISTING resource usage"
    Write-Host "  Best practice: Use BOTH together!"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "current_sizing" {
  description = "Current environment sizing"
  value = {
    environment = var.environment
    sizes       = local.current_sizes
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    right_sizing     = "Use environment-based maps to automatically right-size resources"
    cost_estimation  = "Use Infracost to estimate costs before terraform apply"
    scheduling       = "Stop non-prod resources at night/weekends for 65% savings"
    spot_instances   = "Use spot/preemptible instances for non-critical workloads"
    lifecycle        = "Set S3/storage lifecycle rules to archive and delete old data"
    reserved         = "Use reserved instances or savings plans for steady-state production"
  }
}
