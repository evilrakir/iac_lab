# ╔════════════════════════════════════════════════════════════════════╗
# ║  STATE LOCKING AND CONCURRENCY                                   ║
# ║  Prevent simultaneous modifications to infrastructure            ║
# ╚════════════════════════════════════════════════════════════════════╝

# When multiple people or pipelines run Terraform at the same time,
# state corruption can occur. State locking prevents this by ensuring
# only one operation modifies state at a time. This exercise demonstrates
# locking concepts and troubleshooting using the local provider.

# POWERSHELL COMPARISON:
# =====================
# Like file locks in PowerShell preventing two scripts from writing
# to the same file simultaneously:
#   $stream = [System.IO.File]::Open($path, 'Open', 'ReadWrite', 'None')
# Terraform does this automatically with remote backends.

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

variable "team_members" {
  description = "Team members who might run Terraform"
  type        = list(string)
  default     = ["alice", "bob", "ci-pipeline"]
}

# ========================================================================
# SECTION 1: HOW STATE LOCKING WORKS
# ========================================================================

resource "local_file" "locking_explained" {
  filename = "./terraform-lab-output/state-locking/how-locking-works.md"
  content  = <<-EOT
    # How Terraform State Locking Works

    ## The Problem
    ```
    Time     Alice                    Bob
    -----    -----                    ---
    10:00    terraform plan
    10:01    (reads state)            terraform plan
    10:02    terraform apply          (reads state)
    10:03    (writes state) ✓         terraform apply
    10:04                             (writes state) ✗ CORRUPTED!
    ```

    Without locking, Bob's apply overwrites Alice's changes because
    his plan was based on stale state.

    ## The Solution: State Locking
    ```
    Time     Alice                    Bob
    -----    -----                    ---
    10:00    terraform apply
    10:01    (acquires lock) ✓        terraform apply
    10:02    (modifying state)        (waiting for lock...)
    10:03    (releases lock) ✓        (acquires lock) ✓
    10:04                             (reads fresh state)
    10:05                             (applies correctly) ✓
    ```

    ## Lock Info
    When Terraform acquires a lock, it stores:
    - **ID**: Unique lock identifier
    - **Operation**: plan, apply, destroy, etc.
    - **Who**: Username and hostname
    - **When**: Timestamp of lock acquisition
    - **Version**: Terraform version
    - **Path**: State file path

    ## Backends That Support Locking
    | Backend | Locking Mechanism |
    |---------|------------------|
    | S3 | DynamoDB table |
    | Azure Storage | Blob leases (built-in) |
    | GCS | Built-in |
    | Consul | Key/Value locks |
    | PostgreSQL | Advisory locks |
    | HTTP | Optional (depends on server) |
    | Local | File system locks (.terraform.lock.hcl) |
  EOT
}

# ========================================================================
# SECTION 2: SIMULATED LOCK SCENARIOS
# ========================================================================

# Simulate what a lock record looks like
resource "local_file" "lock_example" {
  filename = "./terraform-lab-output/state-locking/example-lock-info.json"
  content = jsonencode({
    title       = "Example Terraform Lock Record"
    description = "This is what Terraform stores when it acquires a lock"
    lock_info = {
      ID        = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
      Operation = "OperationTypeApply"
      Info      = ""
      Who       = "alice@WORKSTATION"
      Version   = "1.6.0"
      Created   = "2024-01-15T10:30:00Z"
      Path      = "terraform-lab/development/terraform.tfstate"
    }
    stored_in = {
      aws     = "DynamoDB table row with LockID as partition key"
      azure   = "Blob lease on the state file"
      gcs     = "Object lock on the state file"
      consul  = "Key-value entry with session"
    }
  })
}

# Simulate race condition scenarios
resource "local_file" "race_conditions" {
  filename = "./terraform-lab-output/state-locking/race-condition-scenarios.json"
  content = jsonencode({
    title = "State Locking Race Condition Scenarios"
    scenarios = [
      {
        name        = "Concurrent Apply"
        risk        = "HIGH"
        description = "Two people run 'terraform apply' at the same time"
        without_lock = "State corruption - resources may be created twice or state becomes inconsistent"
        with_lock    = "Second apply waits for first to complete, then runs with fresh state"
      },
      {
        name        = "Plan While Apply Running"
        risk        = "MEDIUM"
        description = "Someone runs 'plan' while 'apply' is in progress"
        without_lock = "Plan shows stale data, potentially misleading"
        with_lock    = "Plan waits for apply to finish, shows accurate state"
      },
      {
        name        = "CI/CD Pipeline Overlap"
        risk        = "HIGH"
        description = "Two pipeline runs trigger at the same time"
        without_lock = "Both pipelines modify infrastructure simultaneously"
        with_lock    = "Pipelines queue automatically, run sequentially"
      },
      {
        name        = "Destroy During Apply"
        risk        = "CRITICAL"
        description = "Someone runs 'destroy' while 'apply' is creating resources"
        without_lock = "Catastrophic - partial infrastructure, orphaned resources"
        with_lock    = "Destroy waits for apply to complete"
      }
    ]
  })
}

# ========================================================================
# SECTION 3: FORCE-UNLOCK AND TROUBLESHOOTING
# ========================================================================

resource "local_file" "troubleshooting" {
  filename = "./terraform-lab-output/state-locking/troubleshooting-guide.md"
  content  = <<-EOT
    # State Lock Troubleshooting Guide

    ## Error: "Error acquiring the state lock"
    ```
    Error: Error acquiring the state lock

    Error message: ConditionalCheckFailedException: The conditional request failed
    Lock Info:
      ID:        a1b2c3d4-e5f6-7890-abcd-ef1234567890
      Path:      terraform-lab/development/terraform.tfstate
      Operation: OperationTypeApply
      Who:       alice@WORKSTATION
      Version:   1.6.0
      Created:   2024-01-15 10:30:00.000000 +0000 UTC
    ```

    ## Step-by-Step Resolution

    ### Step 1: Check if another operation is running
    - Ask your team if anyone is running Terraform
    - Check CI/CD pipelines for active runs
    - Check if a previous run crashed without releasing the lock

    ### Step 2: Wait and retry
    Most locks resolve themselves:
    ```bash
    # Wait a few minutes, then retry
    terraform plan
    ```

    ### Step 3: Force-unlock (LAST RESORT)
    Only use this if you're CERTAIN no operation is running:
    ```bash
    # Get the lock ID from the error message
    terraform force-unlock a1b2c3d4-e5f6-7890-abcd-ef1234567890
    ```

    ⚠️ WARNING: Force-unlocking while an operation is running
    WILL cause state corruption. Always verify first!

    ### Step 4: If state is corrupted
    ```bash
    # List state versions (S3 versioning)
    aws s3api list-object-versions \
      --bucket my-terraform-state \
      --prefix development/terraform.tfstate

    # Restore a previous version
    aws s3api get-object \
      --bucket my-terraform-state \
      --key development/terraform.tfstate \
      --version-id PREVIOUS_VERSION_ID \
      terraform.tfstate.backup

    # Review the backup, then upload it
    aws s3 cp terraform.tfstate.backup \
      s3://my-terraform-state/development/terraform.tfstate
    ```

    ## Prevention Best Practices
    1. Always use remote state with locking enabled
    2. Use CI/CD pipelines with queuing (not parallel runs)
    3. Set reasonable lock timeouts
    4. Train team members on lock awareness
    5. Monitor for stale locks (older than 1 hour)
  EOT
}

# ========================================================================
# SECTION 4: LOCK CONFIGURATION EXAMPLES
# ========================================================================

resource "local_file" "lock_configs" {
  filename = "./terraform-lab-output/state-locking/lock-configuration-examples.tf"
  content  = <<-EOT
    # ============================================
    # STATE LOCKING CONFIGURATION EXAMPLES
    # ============================================

    # --- AWS S3 + DynamoDB Locking ---
    terraform {
      backend "s3" {
        bucket         = "${var.project_name}-terraform-state"
        key            = "production/terraform.tfstate"
        region         = "us-east-1"
        encrypt        = true
        dynamodb_table = "${var.project_name}-terraform-locks"
        # DynamoDB provides consistent locking
      }
    }

    # DynamoDB table for locking (bootstrap resource)
    # resource "aws_dynamodb_table" "locks" {
    #   name         = "${var.project_name}-terraform-locks"
    #   billing_mode = "PAY_PER_REQUEST"
    #   hash_key     = "LockID"
    #   attribute {
    #     name = "LockID"
    #     type = "S"
    #   }
    # }

    # --- Azure Built-in Locking ---
    # terraform {
    #   backend "azurerm" {
    #     resource_group_name  = "rg-tfstate"
    #     storage_account_name = "tfstate12345"
    #     container_name       = "tfstate"
    #     key                  = "prod.terraform.tfstate"
    #     # Locking is automatic via blob leases!
    #   }
    # }

    # --- Consul Locking ---
    # terraform {
    #   backend "consul" {
    #     address = "consul.example.com:8500"
    #     scheme  = "https"
    #     path    = "terraform/production"
    #     lock    = true  # Explicit lock enable
    #   }
    # }

    # --- Disable Locking (NOT RECOMMENDED) ---
    # terraform plan -lock=false
    # terraform apply -lock=false
    # Only use for debugging or read-only operations
  EOT
}

# ========================================================================
# SECTION 5: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-state-locking.ps1"
  content  = <<-EOT
    # State Locking: Terraform vs PowerShell Approaches
    # ===================================================

    # TERRAFORM LOCKING             | POWERSHELL EQUIVALENT
    # ------------------------------|-------------------------------
    # Automatic on apply/plan       | Manual file lock implementation
    # DynamoDB / Blob lease         | [System.IO.File]::Open()
    # terraform force-unlock        | Remove lock file manually
    # Lock timeout built-in         | Custom timeout logic
    # Lock info (who, when, what)   | Custom metadata

    # PowerShell: Manual file locking (fragile!)
    # -------------------------------------------
    function Lock-StateFile {
        param([string]$$StatePath)

        $$lockPath = "$$StatePath.lock"

        # Check for existing lock
        if (Test-Path $$lockPath) {
            $$lockInfo = Get-Content $$lockPath | ConvertFrom-Json
            $$lockAge = (Get-Date) - [DateTime]$$lockInfo.Created

            if ($$lockAge.TotalMinutes -lt 30) {
                throw "State is locked by $$($lockInfo.Who) since $$($lockInfo.Created)"
            }
            Write-Warning "Stale lock detected ($$($lockAge.TotalMinutes) min old). Removing..."
        }

        # Create lock
        $$lock = @{
            Who     = "$$env:USERNAME@$$env:COMPUTERNAME"
            Created = (Get-Date).ToString('o')
            PID     = $$PID
        } | ConvertTo-Json

        Set-Content -Path $$lockPath -Value $$lock
        return $$lockPath
    }

    function Unlock-StateFile {
        param([string]$$StatePath)
        Remove-Item "$$StatePath.lock" -ErrorAction SilentlyContinue
    }

    # Usage (fragile - no atomic operations!)
    # try {
    #     $$lock = Lock-StateFile -StatePath "\\server\state\prod.xml"
    #     # ... modify infrastructure ...
    # } finally {
    #     Unlock-StateFile -StatePath "\\server\state\prod.xml"
    # }

    Write-Host "Key Insight:" -ForegroundColor Yellow
    Write-Host "  Terraform state locking is:"
    Write-Host "  - Automatic (no code needed)"
    Write-Host "  - Atomic (uses database transactions)"
    Write-Host "  - Informational (tracks who, when, what)"
    Write-Host "  - Recoverable (force-unlock for emergencies)"
    Write-Host ""
    Write-Host "  PowerShell locking is:"
    Write-Host "  - Manual (you write the code)"
    Write-Host "  - Fragile (file-based, not atomic)"
    Write-Host "  - Limited (no built-in metadata)"
    Write-Host "  - Error-prone (crash = orphaned lock)"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "generated_files" {
  description = "Generated reference files"
  value = {
    locking_guide   = local_file.locking_explained.filename
    lock_example    = local_file.lock_example.filename
    troubleshooting = local_file.troubleshooting.filename
    lock_configs    = local_file.lock_configs.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    purpose        = "State locking prevents concurrent modifications and corruption"
    automatic      = "Remote backends handle locking automatically"
    aws_locking    = "S3 backend uses DynamoDB table for lock storage"
    azure_locking  = "Azure backend uses blob leases (built-in, no extra resources)"
    force_unlock   = "Only use 'terraform force-unlock' as a last resort"
    prevention     = "Use CI/CD queuing and team communication to minimize conflicts"
  }
}
