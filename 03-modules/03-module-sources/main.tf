# ╔════════════════════════════════════════════════════════════════════╗
# ║  MODULE SOURCES - WHERE MODULES COME FROM                       ║
# ║  Learn all the ways to reference and load Terraform modules      ║
# ╚════════════════════════════════════════════════════════════════════╝

# Terraform modules can come from many sources. This exercise teaches
# you about local paths, Git repos, the Terraform Registry, and more.

# POWERSHELL COMPARISON:
# =====================
# Module sources are like PowerShell module paths:
#   Import-Module ./local/path        = source = "./path"
#   Install-Module from PSGallery     = source = "registry/module"
#   Import-Module from network share  = source = "git::url"

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
# SECTION 1: LOCAL PATH SOURCES
# ========================================================================
# The simplest source - a directory on your filesystem.
# This is what we've been using in previous exercises.

# Relative path (most common for project modules)
module "local_relative" {
  source = "./modules/config-generator"

  app_name    = "local-app"
  environment = "development"
}

# ========================================================================
# SECTION 2: ALL SOURCE TYPES DOCUMENTED
# ========================================================================
# Terraform supports many source types. We can't use remote sources
# in this lab (no network dependency), but here's a comprehensive
# reference file showing every source type with real examples.

resource "local_file" "source_reference" {
  filename = "./terraform-lab-output/module-source-reference.tf"
  content  = <<-EOT
    # ============================================
    # TERRAFORM MODULE SOURCE TYPES - REFERENCE
    # ============================================
    # This file documents all module source types.
    # Copy these patterns into your own projects!

    # ----- 1. LOCAL PATH -----
    # Relative to the current module
    module "local_example" {
      source = "./modules/my-module"
      # or
      source = "../shared-modules/networking"
    }

    # ----- 2. TERRAFORM REGISTRY -----
    # Public registry: registry.terraform.io
    module "registry_example" {
      source  = "hashicorp/consul/aws"
      version = "0.1.0"  # Always pin versions!
    }

    # Private registry
    module "private_registry" {
      source  = "app.terraform.io/my-org/my-module/aws"
      version = "~> 1.0"
    }

    # ----- 3. GITHUB -----
    module "github_https" {
      source = "github.com/hashicorp/example"
    }

    module "github_ssh" {
      source = "git@github.com:hashicorp/example.git"
    }

    # Specific branch, tag, or subdirectory
    module "github_ref" {
      source = "git::https://github.com/org/repo.git//modules/vpc?ref=v1.2.0"
    }

    # ----- 4. GENERIC GIT -----
    module "git_example" {
      source = "git::https://example.com/repo.git"
    }

    module "git_branch" {
      source = "git::https://example.com/repo.git?ref=feature-branch"
    }

    # ----- 5. HTTP/HTTPS URLs -----
    module "http_example" {
      source = "https://example.com/modules/vpc-module.zip"
    }

    # ----- 6. S3 BUCKET -----
    module "s3_example" {
      source = "s3::https://s3-eu-west-1.amazonaws.com/bucket/module.zip"
    }

    # ----- 7. GCS BUCKET -----
    module "gcs_example" {
      source = "gcs::https://www.googleapis.com/storage/v1/bucket/module.zip"
    }

    # ============================================
    # VERSION CONSTRAINTS
    # ============================================
    # Only works with registry sources!
    #
    # = 1.0.0    Exact version
    # >= 1.0.0   Minimum version
    # ~> 1.0     Any 1.x version (>= 1.0, < 2.0)
    # ~> 1.0.0   Any 1.0.x version (>= 1.0.0, < 1.1.0)
    # >= 1.0, < 2.0   Range constraint

    # PowerShell equivalent:
    # Install-Module -Name SomeModule -RequiredVersion 1.0.0
    # Install-Module -Name SomeModule -MinimumVersion 1.0.0
  EOT
}

# ========================================================================
# SECTION 3: VERSION PINNING DEMONSTRATION
# ========================================================================

resource "local_file" "version_strategies" {
  filename = "./terraform-lab-output/version-pinning-guide.json"
  content  = jsonencode({
    title = "Module Version Pinning Strategies"
    strategies = {
      exact = {
        syntax      = "version = \"1.0.0\""
        use_case    = "Production - maximum stability"
        risk        = "Won't get security patches automatically"
        ps_equiv    = "Install-Module -RequiredVersion 1.0.0"
      }
      pessimistic = {
        syntax      = "version = \"~> 1.0\""
        use_case    = "Recommended - allows minor updates"
        risk        = "May get new features, but no breaking changes"
        ps_equiv    = "Install-Module -MinimumVersion 1.0 -MaximumVersion 1.99"
      }
      minimum = {
        syntax      = "version = \">= 1.0.0\""
        use_case    = "Development - always latest"
        risk        = "Breaking changes possible on major version bumps"
        ps_equiv    = "Install-Module -MinimumVersion 1.0.0"
      }
      range = {
        syntax      = "version = \">= 1.0.0, < 2.0.0\""
        use_case    = "Balanced - stay within major version"
        risk        = "Low risk of breaking changes"
        ps_equiv    = "Custom logic with Get-Module -ListAvailable"
      }
    }
    recommendation = "Use ~> (pessimistic constraint) for most modules"
  })
}

# ========================================================================
# SECTION 4: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-module-sources.ps1"
  content  = <<-EOT
    # PowerShell vs Terraform: Module Sources Comparison
    # ===================================================

    # TERRAFORM SOURCE       | POWERSHELL EQUIVALENT
    # -----------------------|-----------------------------------
    # source = "./local"     | Import-Module ./local/MyModule.psm1
    # source = "reg/module"  | Install-Module -Name ModuleName
    # source = "git::url"    | git clone url; Import-Module ...
    # source = "s3::url"     | Save-Module from custom repo
    # version = "~> 1.0"     | -MinimumVersion / -MaximumVersion

    # PowerShell module sources
    Write-Host "=== PowerShell Module Sources ===" -ForegroundColor Yellow

    # 1. Local path
    # Import-Module -Name "C:\Modules\MyModule"
    Write-Host "Local: Import-Module ./path/to/module"

    # 2. PSGallery (like Terraform Registry)
    # Find-Module -Name Az.Compute
    # Install-Module -Name Az.Compute -RequiredVersion 5.0.0
    Write-Host "Gallery: Install-Module -Name Az.Compute"

    # 3. Private repository
    # Register-PSRepository -Name Internal -SourceLocation https://...
    # Install-Module -Name MyModule -Repository Internal
    Write-Host "Private: Install-Module -Repository Internal"

    # 4. Git repository
    # git clone https://github.com/org/ps-module.git
    # Import-Module ./ps-module/MyModule.psd1
    Write-Host "Git: Clone then Import-Module"

    Write-Host "`nKey Difference:" -ForegroundColor Cyan
    Write-Host "  Terraform: 'terraform init' downloads modules automatically"
    Write-Host "  PowerShell: You must Install-Module or Import-Module manually"
    Write-Host "  Terraform: Modules are versioned per-project in .terraform/"
    Write-Host "  PowerShell: Modules installed system-wide or per-user"
  EOT
}

# ========================================================================
# LOCAL MODULE (used by Section 1)
# ========================================================================
# This is defined in ./modules/config-generator/ below

# ========================================================================
# OUTPUTS
# ========================================================================

output "module_output" {
  description = "Output from locally-sourced module"
  value       = module.local_relative.config_summary
}

output "source_reference_path" {
  description = "Path to the source type reference file"
  value       = local_file.source_reference.filename
}

output "lesson_summary" {
  description = "Key takeaways from this exercise"
  value = {
    local_sources    = "Use relative paths for project-specific modules"
    registry_sources = "Use Terraform Registry for community/verified modules"
    git_sources      = "Use Git URLs for private/internal modules"
    version_pinning  = "Always pin versions with ~> constraint in production"
  }
}
