# ╔════════════════════════════════════════════════════════════════════╗
# ║  SECURITY BEST PRACTICES                                        ║
# ║  Managing secrets and securing Terraform workflows              ║
# ╚════════════════════════════════════════════════════════════════════╝

# Security is critical in infrastructure as code. Terraform configs often
# contain or reference sensitive data (passwords, API keys, certificates).
# This exercise demonstrates how to handle secrets properly.

# POWERSHELL COMPARISON:
# =====================
# Like PowerShell's SecureString and credential management:
#   $cred = Get-Credential; $cred.Password  (encrypted in memory)
# Terraform uses: sensitive variables, Vault integration, env vars

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
# SECTION 1: SENSITIVE VARIABLES
# ========================================================================

variable "database_password" {
  description = "Database password - marked sensitive"
  type        = string
  default     = "CHANGE_ME_IN_PRODUCTION"
  sensitive   = true  # Won't show in plan output or logs
}

variable "api_key" {
  description = "API key for external service"
  type        = string
  default     = "demo-key-not-real"
  sensitive   = true
}

resource "local_file" "sensitive_vars_guide" {
  filename = "./terraform-lab-output/security/sensitive-variables.tf"
  content  = <<-EOT
    # ============================================
    # SENSITIVE VARIABLE PATTERNS
    # ============================================

    # Mark variables as sensitive to hide from output
    variable "db_password" {
      description = "Database password"
      type        = string
      sensitive   = true
    }

    # Pass sensitive values via environment variables
    # export TF_VAR_db_password="my-secret-password"
    # terraform apply

    # Pass via .tfvars file (don't commit!)
    # secret.tfvars:
    #   db_password = "my-secret-password"
    # terraform apply -var-file="secret.tfvars"

    # Sensitive outputs
    output "db_connection_string" {
      value     = "postgresql://admin:$${var.db_password}@db.example.com:5432/mydb"
      sensitive = true  # Hidden in terraform output
    }

    # Retrieve with: terraform output -raw db_connection_string
  EOT
}

# ========================================================================
# SECTION 2: SECRET MANAGEMENT PATTERNS
# ========================================================================

resource "local_file" "secret_patterns" {
  filename = "./terraform-lab-output/security/secret-management-patterns.md"
  content  = <<-EOT
    # Terraform Secret Management Patterns

    ## Pattern 1: Environment Variables (Simplest)
    ```bash
    export TF_VAR_db_password="my-password"
    export AWS_ACCESS_KEY_ID="AKIA..."
    terraform apply
    ```
    - Pros: Simple, works everywhere
    - Cons: Visible in process list, shell history

    ## Pattern 2: .tfvars File (Team-Friendly)
    ```hcl
    # secret.tfvars (add to .gitignore!)
    db_password = "my-password"
    api_key     = "sk-abc123"
    ```
    ```bash
    terraform apply -var-file="secret.tfvars"
    ```
    - Pros: Easy to manage, can encrypt file
    - Cons: File on disk, must manage access

    ## Pattern 3: HashiCorp Vault (Production)
    ```hcl
    data "vault_generic_secret" "db" {
      path = "secret/database"
    }

    resource "aws_db_instance" "main" {
      password = data.vault_generic_secret.db.data["password"]
    }
    ```
    - Pros: Centralized, audited, rotatable
    - Cons: Requires Vault infrastructure

    ## Pattern 4: Cloud Secret Manager
    ```hcl
    # AWS Secrets Manager
    data "aws_secretsmanager_secret_version" "db" {
      secret_id = "prod/database/password"
    }

    # Azure Key Vault
    data "azurerm_key_vault_secret" "db" {
      name         = "db-password"
      key_vault_id = azurerm_key_vault.main.id
    }
    ```
    - Pros: Cloud-native, integrated IAM
    - Cons: Cloud-specific

    ## Pattern 5: SOPS Encrypted Files
    ```bash
    # Encrypt with SOPS
    sops -e secrets.yaml > secrets.enc.yaml
    # Decrypt in Terraform via external data source
    ```
    - Pros: Can commit encrypted files to Git
    - Cons: Key management complexity

    ## What NEVER to Do
    1. Hard-code secrets in .tf files
    2. Commit .tfvars with secrets to Git
    3. Store secrets in state without encryption
    4. Print sensitive values in outputs
    5. Share state files via unencrypted channels
  EOT
}

# ========================================================================
# SECTION 3: STATE FILE SECURITY
# ========================================================================

resource "local_file" "state_security" {
  filename = "./terraform-lab-output/security/state-file-security.json"
  content = jsonencode({
    title = "Terraform State File Security"
    warning = "State files contain ALL resource data including secrets in PLAINTEXT"
    risks = [
      "Database passwords stored in state",
      "API keys and tokens in resource attributes",
      "Private keys for TLS certificates",
      "Any sensitive variable values used in resources"
    ]
    mitigations = {
      encryption_at_rest = {
        aws   = "Enable S3 bucket encryption with SSE-KMS"
        azure = "Storage Account encryption is enabled by default"
        gcs   = "GCS encryption is enabled by default"
      }
      access_control = {
        aws   = "Restrict S3 bucket policy to Terraform IAM role only"
        azure = "Use RBAC to limit Storage Account access"
        gcs   = "Use IAM policies on the GCS bucket"
      }
      encryption_in_transit = "Always use HTTPS for backend connections"
      audit_logging = "Enable access logging on state storage"
      versioning = "Enable versioning for state rollback"
    }
    least_privilege = {
      description = "Terraform should only have permissions it needs"
      examples = [
        "Create separate IAM roles per project/environment",
        "Use short-lived credentials (STS, managed identity)",
        "Never use root/admin credentials for Terraform",
        "Rotate credentials regularly"
      ]
    }
  })
}

# ========================================================================
# SECTION 4: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-security.ps1"
  content  = <<-EOT
    # Security: Terraform vs PowerShell Secret Management
    # =====================================================

    # TERRAFORM                        | POWERSHELL
    # ---------------------------------|-------------------------------
    # sensitive = true                 | [SecureString]
    # TF_VAR_password env var          | $$env:DB_PASSWORD
    # Vault data source               | Get-AzKeyVaultSecret
    # -var-file="secret.tfvars"       | Import-Clixml (encrypted)
    # State encryption                 | DPAPI / Certificate encryption

    # PowerShell: Credential management patterns

    # Pattern 1: SecureString
    $$securePass = ConvertTo-SecureString "MyPassword" -AsPlainText -Force
    $$credential = New-Object PSCredential("admin", $$securePass)
    # $$credential.GetNetworkCredential().Password  # to decrypt

    # Pattern 2: Export/Import encrypted credentials
    # Only works for the same user on the same machine (DPAPI)
    $$credential | Export-Clixml -Path "C:\secure\cred.xml"
    $$savedCred = Import-Clixml -Path "C:\secure\cred.xml"

    # Pattern 3: Azure Key Vault
    # $$secret = Get-AzKeyVaultSecret -VaultName "myVault" -Name "dbPassword"
    # $$password = $$secret.SecretValue

    # Pattern 4: Windows Credential Manager
    # Install-Module CredentialManager
    # New-StoredCredential -Target "MyApp" -UserName "admin" -Password "secret"
    # $$cred = Get-StoredCredential -Target "MyApp"

    Write-Host "Security Comparison:" -ForegroundColor Yellow
    Write-Host "  Terraform: Secrets in state file (encrypt the state!)"
    Write-Host "  PowerShell: Secrets in memory only (DPAPI encrypted on disk)"
    Write-Host ""
    Write-Host "  Both need: Vault/Key Vault for production secret management"
    Write-Host "  Both need: Never hardcode secrets in source files"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "security_files" {
  description = "Generated security reference files"
  value = {
    sensitive_vars = local_file.sensitive_vars_guide.filename
    secret_patterns = local_file.secret_patterns.filename
    state_security = local_file.state_security.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    sensitive_vars  = "Mark sensitive variables with 'sensitive = true'"
    env_vars        = "Use TF_VAR_ environment variables for secrets"
    vault           = "Use HashiCorp Vault or cloud secret managers in production"
    state_security  = "State files contain secrets - always encrypt at rest"
    least_privilege = "Give Terraform only the permissions it needs"
    never_commit    = "Never commit secrets to Git (use .gitignore)"
  }
}
