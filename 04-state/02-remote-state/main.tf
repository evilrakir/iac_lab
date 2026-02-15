# ╔════════════════════════════════════════════════════════════════════╗
# ║  REMOTE STATE BACKENDS                                           ║
# ║  Store Terraform state remotely for team collaboration           ║
# ╚════════════════════════════════════════════════════════════════════╝

# In production, Terraform state should be stored remotely (S3, Azure Blob,
# GCS) instead of on your local machine. This enables team collaboration,
# state locking, and disaster recovery. This exercise demonstrates remote
# backend patterns using the local provider to generate reference configs.

# POWERSHELL COMPARISON:
# =====================
# Like storing PowerShell DSC configurations on a shared file server
# instead of each admin's laptop. Everyone references the same source of
# truth, and changes are coordinated instead of conflicting.
# PS:  \\fileserver\DSC\configurations\
# TF:  s3://my-terraform-state/project/terraform.tfstate

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
  description = "Project name for state path organization"
  type        = string
  default     = "terraform-lab"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"
}

variable "region" {
  description = "Primary deployment region"
  type        = string
  default     = "us-east-1"
}

# ========================================================================
# SECTION 1: LOCAL STATE (DEFAULT) vs REMOTE STATE
# ========================================================================

# By default, Terraform stores state locally in terraform.tfstate.
# This works for solo development but fails for teams.

resource "local_file" "state_comparison" {
  filename = "./terraform-lab-output/remote-state/local-vs-remote.md"
  content  = <<-EOT
    # Local State vs Remote State

    ## Local State (Default)
    - File: `terraform.tfstate` in your working directory
    - Single user only
    - No locking - concurrent runs corrupt state
    - Lost if your machine crashes
    - Secrets stored in plaintext on disk

    ## Remote State (Production)
    - Stored in cloud storage (S3, Azure Blob, GCS)
    - Team collaboration - everyone reads same state
    - State locking prevents concurrent modifications
    - Versioned - rollback to previous states
    - Encryption at rest and in transit

    ## When to Switch to Remote State
    1. More than one person works on the infrastructure
    2. You need CI/CD pipelines to run Terraform
    3. You want disaster recovery for your state
    4. You need to share outputs between projects

    ## Migration Command
    ```bash
    # After adding backend configuration:
    terraform init -migrate-state
    # Terraform will copy local state to the remote backend
    ```
  EOT
}

# ========================================================================
# SECTION 2: AWS S3 BACKEND CONFIGURATION
# ========================================================================

resource "local_file" "s3_backend" {
  filename = "./terraform-lab-output/remote-state/aws-s3-backend.tf"
  content  = <<-EOT
    # ============================================
    # AWS S3 BACKEND CONFIGURATION
    # ============================================
    # The most popular remote backend for AWS users.
    # Uses S3 for state storage + DynamoDB for locking.

    terraform {
      backend "s3" {
        # State file location
        bucket = "${var.project_name}-terraform-state"
        key    = "${var.environment}/terraform.tfstate"
        region = "${var.region}"

        # Encryption at rest
        encrypt = true

        # State locking via DynamoDB
        dynamodb_table = "${var.project_name}-terraform-locks"

        # Enable versioning on the S3 bucket for rollback
        # (configured on the bucket itself, not here)
      }
    }

    # ============================================
    # BOOTSTRAP: Create the S3 bucket and DynamoDB table
    # ============================================
    # Run this FIRST with local state, then migrate.
    # This is the "chicken and egg" problem of remote state.

    resource "aws_s3_bucket" "terraform_state" {
      bucket = "${var.project_name}-terraform-state"

      # Prevent accidental deletion
      lifecycle {
        prevent_destroy = true
      }
    }

    resource "aws_s3_bucket_versioning" "terraform_state" {
      bucket = aws_s3_bucket.terraform_state.id
      versioning_configuration {
        status = "Enabled"
      }
    }

    resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
      bucket = aws_s3_bucket.terraform_state.id
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "aws:kms"
        }
      }
    }

    resource "aws_s3_bucket_public_access_block" "terraform_state" {
      bucket = aws_s3_bucket.terraform_state.id

      block_public_acls       = true
      block_public_policy     = true
      ignore_public_acls      = true
      restrict_public_buckets = true
    }

    resource "aws_dynamodb_table" "terraform_locks" {
      name         = "${var.project_name}-terraform-locks"
      billing_mode = "PAY_PER_REQUEST"
      hash_key     = "LockID"

      attribute {
        name = "LockID"
        type = "S"
      }
    }
  EOT
}

# ========================================================================
# SECTION 3: AZURE STORAGE BACKEND CONFIGURATION
# ========================================================================

resource "local_file" "azure_backend" {
  filename = "./terraform-lab-output/remote-state/azure-storage-backend.tf"
  content  = <<-EOT
    # ============================================
    # AZURE STORAGE BACKEND CONFIGURATION
    # ============================================
    # Uses Azure Blob Storage with built-in locking.
    # No separate lock table needed (unlike AWS).

    terraform {
      backend "azurerm" {
        resource_group_name  = "rg-${var.project_name}-tfstate"
        storage_account_name = "${replace(var.project_name, "-", "")}tfstate"
        container_name       = "tfstate"
        key                  = "${var.environment}/terraform.tfstate"

        # Uses Azure AD authentication by default
        # Or set ARM_ACCESS_KEY environment variable
      }
    }

    # ============================================
    # BOOTSTRAP: Create Azure Storage resources
    # ============================================

    resource "azurerm_resource_group" "tfstate" {
      name     = "rg-${var.project_name}-tfstate"
      location = "East US"
    }

    resource "azurerm_storage_account" "tfstate" {
      name                     = "${replace(var.project_name, "-", "")}tfstate"
      resource_group_name      = azurerm_resource_group.tfstate.name
      location                 = azurerm_resource_group.tfstate.location
      account_tier             = "Standard"
      account_replication_type = "GRS"  # Geo-redundant for DR

      # Security
      min_tls_version              = "TLS1_2"
      allow_nested_items_to_be_public = false

      blob_properties {
        versioning_enabled = true  # Rollback support
      }
    }

    resource "azurerm_storage_container" "tfstate" {
      name                  = "tfstate"
      storage_account_name  = azurerm_storage_account.tfstate.name
      container_access_type = "private"
    }
  EOT
}

# ========================================================================
# SECTION 4: GCS BACKEND CONFIGURATION
# ========================================================================

resource "local_file" "gcs_backend" {
  filename = "./terraform-lab-output/remote-state/gcs-backend.tf"
  content  = <<-EOT
    # ============================================
    # GOOGLE CLOUD STORAGE BACKEND
    # ============================================
    # Uses GCS with built-in locking.

    terraform {
      backend "gcs" {
        bucket = "${var.project_name}-terraform-state"
        prefix = "${var.environment}"

        # Authentication via GOOGLE_CREDENTIALS env var
        # or Application Default Credentials
      }
    }

    # Bootstrap: Create GCS bucket
    resource "google_storage_bucket" "tfstate" {
      name     = "${var.project_name}-terraform-state"
      location = "US"

      versioning {
        enabled = true
      }

      uniform_bucket_level_access = true

      lifecycle_rule {
        action {
          type = "Delete"
        }
        condition {
          num_newer_versions = 10  # Keep last 10 versions
        }
      }
    }
  EOT
}

# ========================================================================
# SECTION 5: DATA SHARING BETWEEN PROJECTS
# ========================================================================

resource "local_file" "data_sharing" {
  filename = "./terraform-lab-output/remote-state/cross-project-data-sharing.tf"
  content  = <<-EOT
    # ============================================
    # SHARING DATA BETWEEN TERRAFORM PROJECTS
    # ============================================
    # Remote state lets one project read another's outputs.
    # This is how you share VPC IDs, subnet lists, etc.

    # Project A: Networking (produces outputs)
    # -----------------------------------------
    # output "vpc_id" {
    #   value = aws_vpc.main.id
    # }
    # output "private_subnets" {
    #   value = aws_subnet.private[*].id
    # }

    # Project B: Application (consumes outputs)
    # -------------------------------------------
    data "terraform_remote_state" "networking" {
      backend = "s3"
      config = {
        bucket = "${var.project_name}-terraform-state"
        key    = "networking/terraform.tfstate"
        region = "${var.region}"
      }
    }

    # Use outputs from the networking project
    # resource "aws_instance" "app" {
    #   subnet_id = data.terraform_remote_state.networking.outputs.private_subnets[0]
    #   vpc_security_group_ids = [
    #     data.terraform_remote_state.networking.outputs.app_security_group_id
    #   ]
    # }

    # PowerShell equivalent:
    # $networkConfig = Import-Clixml "\\server\configs\network-state.xml"
    # $subnetId = $networkConfig.SubnetId
  EOT
}

# ========================================================================
# SECTION 6: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-remote-state.ps1"
  content  = <<-EOT
    # Remote State: Terraform vs PowerShell Approaches
    # ==================================================

    # TERRAFORM REMOTE STATE        | POWERSHELL EQUIVALENT
    # ------------------------------|------------------------------------
    # backend "s3" { ... }          | Export-Clixml to shared storage
    # terraform init -migrate-state | Copy-Item to new location
    # terraform_remote_state data   | Import-Clixml from shared storage
    # State locking (DynamoDB)      | File locks / mutex
    # State versioning (S3)         | Manual backups / Git

    # PowerShell: Storing shared configuration state
    # -----------------------------------------------

    # Save infrastructure state (crude equivalent)
    $$infraState = @{
        VpcId         = "vpc-12345"
        Subnets       = @("subnet-a", "subnet-b")
        SecurityGroup = "sg-67890"
        LastModified  = Get-Date
    }

    # Export to shared location (like terraform remote state)
    $$infraState | Export-Clixml -Path "\\\\fileserver\terraform-state\networking.xml"

    # Import from shared location (like terraform_remote_state data source)
    $$networkState = Import-Clixml -Path "\\\\fileserver\terraform-state\networking.xml"
    Write-Host "VPC ID: $$($networkState.VpcId)"

    # The problem: No locking!
    # Two admins can overwrite each other's changes.
    # Terraform solves this with DynamoDB/built-in locks.

    # Attempt at locking (fragile)
    $$lockFile = "\\\\fileserver\terraform-state\networking.lock"
    if (Test-Path $$lockFile) {
        Write-Error "State is locked by another process!"
        return
    }
    New-Item -Path $$lockFile -Value $$env:COMPUTERNAME
    try {
        # ... modify state ...
    } finally {
        Remove-Item $$lockFile -ErrorAction SilentlyContinue
    }

    Write-Host "`nKey Insight:" -ForegroundColor Yellow
    Write-Host "  Terraform remote state provides:"
    Write-Host "  - Atomic locking (no race conditions)"
    Write-Host "  - Automatic encryption"
    Write-Host "  - Version history with rollback"
    Write-Host "  - Cross-project data sharing via outputs"
    Write-Host "  PowerShell requires manual implementation of all these features."
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "generated_files" {
  description = "Generated reference files"
  value = {
    comparison   = local_file.state_comparison.filename
    s3_backend   = local_file.s3_backend.filename
    azure_backend = local_file.azure_backend.filename
    gcs_backend  = local_file.gcs_backend.filename
    data_sharing = local_file.data_sharing.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    why_remote      = "Team collaboration, locking, encryption, and disaster recovery"
    s3_backend      = "S3 + DynamoDB is the most popular AWS backend pattern"
    azure_backend   = "Azure Blob Storage has built-in locking (no separate table)"
    gcs_backend     = "GCS also has built-in locking with versioning"
    data_sharing    = "Use terraform_remote_state data source to share outputs"
    migration       = "Run 'terraform init -migrate-state' to switch backends"
    bootstrap       = "Create backend resources first with local state, then migrate"
  }
}
