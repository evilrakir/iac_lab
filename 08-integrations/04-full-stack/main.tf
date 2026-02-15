# ╔════════════════════════════════════════════════════════════════════╗
# ║  FULL STACK APPLICATION DEPLOYMENT                              ║
# ║  End-to-end infrastructure + application with Terraform         ║
# ╚════════════════════════════════════════════════════════════════════╝

# This capstone exercise brings everything together: networking, compute,
# database, caching, monitoring, and application deployment - all managed
# as a single Terraform configuration. This is what production Terraform
# looks like in the real world.

# POWERSHELL COMPARISON:
# =====================
# Like a comprehensive deployment script that does EVERYTHING:
#   ./Deploy-FullStack.ps1 -Environment prod -Region eastus
# But instead of a 500-line script, it's a declarative config
# with dependency ordering, state tracking, and plan preview.

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
  description = "Project name used across all resources"
  type        = string
  default     = "fullstack-demo"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "region" {
  description = "Primary deployment region"
  type        = string
  default     = "us-east-1"
}

variable "app_config" {
  description = "Application-level configuration"
  type = object({
    domain        = string
    app_version   = string
    min_instances = number
    max_instances = number
    db_engine     = string
    cache_engine  = string
  })
  default = {
    domain        = "app.example.com"
    app_version   = "2.1.0"
    min_instances = 2
    max_instances = 10
    db_engine     = "postgres"
    cache_engine  = "redis"
  }
}

# ========================================================================
# LOCALS - COMPUTED VALUES
# ========================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Version     = var.app_config.app_version
  }

  # Environment-specific sizing
  sizing = {
    production = {
      web_instance   = "t3.large"
      app_instance   = "t3.xlarge"
      db_instance    = "db.r5.large"
      cache_instance = "cache.r5.large"
      db_storage_gb  = 100
    }
    staging = {
      web_instance   = "t3.medium"
      app_instance   = "t3.medium"
      db_instance    = "db.t3.medium"
      cache_instance = "cache.t3.medium"
      db_storage_gb  = 50
    }
    dev = {
      web_instance   = "t3.micro"
      app_instance   = "t3.small"
      db_instance    = "db.t3.micro"
      cache_instance = "cache.t3.micro"
      db_storage_gb  = 20
    }
  }

  current_sizing = local.sizing[var.environment]
}

# ========================================================================
# SECTION 1: FULL STACK ARCHITECTURE
# ========================================================================

resource "local_file" "architecture" {
  filename = "./terraform-lab-output/full-stack/architecture.md"
  content  = <<-EOT
    # Full Stack Architecture: ${var.project_name}
    ## Environment: ${var.environment}

    ```
    Internet
       |
    [Route 53 DNS] -> ${var.app_config.domain}
       |
    [CloudFront CDN]
       |
    [Application Load Balancer]
       |
    +---+---+---+
    | Web Tier  |  (${local.current_sizing.web_instance} x ${var.app_config.min_instances}-${var.app_config.max_instances})
    | (NGINX)   |  Auto-scaling group
    +---+---+---+
       |
    +---+---+---+
    | App Tier  |  (${local.current_sizing.app_instance})
    | (Node.js) |  Container service (ECS/AKS)
    +---+---+---+
       |         \
    +------+   +-------+
    |  RDS |   | Redis |
    | (${local.current_sizing.db_instance}) |   | (${local.current_sizing.cache_instance}) |
    +------+   +-------+
       |
    [S3 Bucket]
    (Static assets, backups)
    ```

    ## Resource Summary
    | Layer | Resource | Size | Count |
    |-------|----------|------|-------|
    | Networking | VPC + Subnets | /16 CIDR | 1 VPC, 6 subnets |
    | Web | ALB + ASG | ${local.current_sizing.web_instance} | ${var.app_config.min_instances}-${var.app_config.max_instances} |
    | App | ECS/Container | ${local.current_sizing.app_instance} | 2+ |
    | Database | RDS ${var.app_config.db_engine} | ${local.current_sizing.db_instance} | 1 primary + 1 replica |
    | Cache | ElastiCache ${var.app_config.cache_engine} | ${local.current_sizing.cache_instance} | 1 cluster |
    | Storage | S3 | Standard | 2 buckets |
    | DNS | Route 53 | - | 1 zone |
    | CDN | CloudFront | - | 1 distribution |
    | Monitoring | CloudWatch | - | Dashboards + Alarms |
  EOT
}

# ========================================================================
# SECTION 2: NETWORK LAYER
# ========================================================================

resource "local_file" "network_layer" {
  filename = "./terraform-lab-output/full-stack/01-network.tf"
  content  = <<-EOT
    # ============================================
    # LAYER 1: NETWORKING
    # ============================================

    # --- VPC ---
    resource "aws_vpc" "main" {
      cidr_block           = "10.0.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
      tags = merge(local.common_tags, { Name = "${local.name_prefix}-vpc" })
    }

    # --- Public Subnets (Web tier, ALB) ---
    resource "aws_subnet" "public" {
      count             = 3
      vpc_id            = aws_vpc.main.id
      cidr_block        = "10.0.$${count.index + 1}.0/24"
      availability_zone = data.aws_availability_zones.available.names[count.index]
      map_public_ip_on_launch = true
      tags = merge(local.common_tags, { Name = "${local.name_prefix}-public-$${count.index}" })
    }

    # --- Private Subnets (App tier, Database) ---
    resource "aws_subnet" "private" {
      count             = 3
      vpc_id            = aws_vpc.main.id
      cidr_block        = "10.0.$${count.index + 10}.0/24"
      availability_zone = data.aws_availability_zones.available.names[count.index]
      tags = merge(local.common_tags, { Name = "${local.name_prefix}-private-$${count.index}" })
    }

    # --- Internet Gateway ---
    resource "aws_internet_gateway" "main" {
      vpc_id = aws_vpc.main.id
      tags   = merge(local.common_tags, { Name = "${local.name_prefix}-igw" })
    }

    # --- NAT Gateway (for private subnets) ---
    resource "aws_nat_gateway" "main" {
      allocation_id = aws_eip.nat.id
      subnet_id     = aws_subnet.public[0].id
      tags          = merge(local.common_tags, { Name = "${local.name_prefix}-nat" })
    }
  EOT
}

# ========================================================================
# SECTION 3: APPLICATION LAYERS
# ========================================================================

resource "local_file" "app_layers" {
  filename = "./terraform-lab-output/full-stack/02-application.tf"
  content  = <<-EOT
    # ============================================
    # LAYER 2: COMPUTE (Web + App)
    # ============================================

    # --- Application Load Balancer ---
    resource "aws_lb" "main" {
      name               = "${local.name_prefix}-alb"
      internal           = false
      load_balancer_type = "application"
      security_groups    = [aws_security_group.alb.id]
      subnets            = aws_subnet.public[*].id
      tags               = local.common_tags
    }

    # --- Auto Scaling Group ---
    resource "aws_autoscaling_group" "web" {
      name                = "${local.name_prefix}-web-asg"
      min_size            = ${var.app_config.min_instances}
      max_size            = ${var.app_config.max_instances}
      desired_capacity    = ${var.app_config.min_instances}
      vpc_zone_identifier = aws_subnet.private[*].id
      target_group_arns   = [aws_lb_target_group.web.arn]

      launch_template {
        id      = aws_launch_template.web.id
        version = "$$Latest"
      }

      tag {
        key                 = "Name"
        value               = "${local.name_prefix}-web"
        propagate_at_launch = true
      }
    }

    # --- Auto Scaling Policy ---
    resource "aws_autoscaling_policy" "cpu_target" {
      name                   = "${local.name_prefix}-cpu-target"
      autoscaling_group_name = aws_autoscaling_group.web.name
      policy_type            = "TargetTrackingScaling"

      target_tracking_configuration {
        predefined_metric_specification {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 70.0
      }
    }

    # ============================================
    # LAYER 3: DATA (Database + Cache)
    # ============================================

    # --- RDS Database ---
    resource "aws_db_instance" "main" {
      identifier           = "${local.name_prefix}-db"
      engine               = "${var.app_config.db_engine}"
      engine_version       = "15.4"
      instance_class       = "${local.current_sizing.db_instance}"
      allocated_storage    = ${local.current_sizing.db_storage_gb}
      storage_encrypted    = true
      multi_az             = ${var.environment == "production"}
      db_subnet_group_name = aws_db_subnet_group.main.name
      vpc_security_group_ids = [aws_security_group.db.id]

      # Backup configuration
      backup_retention_period = ${var.environment == "production" ? 7 : 1}
      backup_window           = "03:00-04:00"
      maintenance_window      = "sun:04:00-sun:05:00"

      tags = local.common_tags
    }

    # --- ElastiCache Redis ---
    resource "aws_elasticache_cluster" "main" {
      cluster_id           = "${local.name_prefix}-cache"
      engine               = "${var.app_config.cache_engine}"
      node_type            = "${local.current_sizing.cache_instance}"
      num_cache_nodes      = 1
      parameter_group_name = "default.redis7"
      subnet_group_name    = aws_elasticache_subnet_group.main.name
      security_group_ids   = [aws_security_group.cache.id]
      tags                 = local.common_tags
    }
  EOT
}

# ========================================================================
# SECTION 4: DEPLOYMENT CHECKLIST
# ========================================================================

resource "local_file" "deployment_checklist" {
  filename = "./terraform-lab-output/full-stack/deployment-checklist.json"
  content = jsonencode({
    title = "Full Stack Deployment Checklist"
    pre_deployment = [
      "Review terraform plan output carefully",
      "Verify environment variables are set correctly",
      "Confirm database backup exists (for updates)",
      "Check that DNS records are ready",
      "Verify SSL certificates are provisioned",
      "Review security group rules",
      "Confirm cost estimates with Infracost"
    ]
    deployment_order = [
      "1. Network layer (VPC, subnets, gateways)",
      "2. Security groups and IAM roles",
      "3. Database and cache (takes longest)",
      "4. Application tier (containers/instances)",
      "5. Load balancer and target groups",
      "6. DNS and CDN configuration",
      "7. Monitoring and alerting setup"
    ]
    post_deployment = [
      "Verify health check endpoints",
      "Check application logs for errors",
      "Validate database connectivity",
      "Test cache hit rates",
      "Verify monitoring alerts are firing correctly",
      "Run smoke tests against the deployed application",
      "Update deployment documentation"
    ]
    rollback_plan = {
      immediate  = "terraform apply with previous state version"
      database   = "Restore from RDS snapshot"
      dns        = "Update Route53 to point to previous version"
      full       = "terraform destroy + terraform apply from known-good state"
    }
  })
}

# ========================================================================
# SECTION 5: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-fullstack.ps1"
  content  = <<-EOT
    # Full Stack: Terraform vs PowerShell Deployment
    # ================================================

    # A full stack deployment script in PowerShell might look like:
    # param(
    #   [string]$$Environment = "production",
    #   [string]$$Region = "eastus"
    # )
    #
    # # Step 1: Network
    # $$rg = New-AzResourceGroup -Name "myapp-$$Environment-rg" -Location $$Region
    # $$vnet = New-AzVirtualNetwork -Name "myapp-vnet" ...
    #
    # # Step 2: Database
    # $$sqlServer = New-AzSqlServer -ServerName "myapp-sql" ...
    # $$sqlDb = New-AzSqlDatabase -DatabaseName "myapp-db" ...
    #
    # # Step 3: App Service
    # $$plan = New-AzAppServicePlan -Name "myapp-plan" ...
    # $$app = New-AzWebApp -Name "myapp-web" ...
    #
    # # Step 4: DNS
    # New-AzDnsRecordSet -Name "app" -ZoneName "example.com" ...
    #
    # # Problem: What if Step 3 fails? Steps 1-2 exist but aren't tracked!

    Write-Host "Full Stack Deployment: Terraform Advantage" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  PowerShell script: 300+ lines, manual error handling" -ForegroundColor Red
    Write-Host "  Terraform config:  Declarative, dependency-aware" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Key Differences:" -ForegroundColor Cyan
    Write-Host "  1. STATE: TF knows what exists, PS scripts don't"
    Write-Host "  2. DEPENDENCIES: TF resolves order, PS must order manually"
    Write-Host "  3. ROLLBACK: TF can destroy cleanly, PS needs manual cleanup"
    Write-Host "  4. PREVIEW: TF plan shows exactly what will change"
    Write-Host "  5. IDEMPOTENT: TF apply is safe to run repeatedly"
    Write-Host ""
    Write-Host "  This is WHY Terraform exists - managing complex" -ForegroundColor Magenta
    Write-Host "  multi-resource deployments that scripts can't handle safely."
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "stack_config" {
  description = "Full stack configuration summary"
  value = {
    project     = var.project_name
    environment = var.environment
    sizing      = local.current_sizing
    app_config  = var.app_config
    tags        = local.common_tags
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    architecture    = "Full stack = networking + compute + data + monitoring in one config"
    dependencies    = "Terraform resolves resource ordering automatically"
    environment     = "Use locals maps for environment-specific sizing"
    state_tracking  = "Terraform state tracks ALL resources for clean updates and rollback"
    deployment      = "Always: plan -> review -> apply (never skip the review)"
    capstone        = "This exercise demonstrates everything learned in the full lab series"
  }
}
