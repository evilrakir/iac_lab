# ╔════════════════════════════════════════════════════════════════════╗
# ║  TERRAFORM MODULE REGISTRY                                      ║
# ║  Learn to discover, evaluate, and use community modules          ║
# ╚════════════════════════════════════════════════════════════════════╝

# The Terraform Registry (registry.terraform.io) is a public catalog
# of reusable modules. Think of it as PowerShell Gallery for infrastructure.
# This exercise teaches you how to find, evaluate, and use registry modules.

# NOTE: This exercise uses the local provider to simulate registry module
# patterns. The generated files show you exactly how to use real modules.

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
# SECTION 1: HOW THE REGISTRY WORKS
# ========================================================================

resource "local_file" "registry_guide" {
  filename = "./terraform-lab-output/registry-guide.md"
  content  = <<-EOT
    # Terraform Registry Guide

    ## Finding Modules

    Visit: https://registry.terraform.io/browse/modules

    ### Popular Modules by Provider

    | Module | Source | Description |
    |--------|--------|-------------|
    | AWS VPC | `terraform-aws-modules/vpc/aws` | Production-ready VPC |
    | Azure Network | `Azure/network/azurerm` | Azure virtual networks |
    | GCP Project | `terraform-google-modules/project-factory/google` | GCP projects |
    | Kubernetes | `terraform-aws-modules/eks/aws` | Amazon EKS clusters |

    ## Using a Registry Module

    ```hcl
    module "vpc" {
      source  = "terraform-aws-modules/vpc/aws"
      version = "~> 5.0"   # ALWAYS pin the version!

      name = "my-vpc"
      cidr = "10.0.0.0/16"

      azs             = ["us-east-1a", "us-east-1b"]
      private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
      public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
    }
    ```

    ## Evaluating a Module

    Before using any module, check:
    1. Downloads/popularity - Is it widely used?
    2. Last updated - Is it maintained?
    3. Verified badge - Is it from a trusted publisher?
    4. Documentation - Are inputs/outputs well documented?
    5. Source code - Review for security issues
    6. Version history - Is it stable?

    ## Module Naming Convention

    Registry modules follow: `namespace/name/provider`
    Examples:
    - `hashicorp/consul/aws` (HashiCorp's Consul on AWS)
    - `terraform-aws-modules/vpc/aws` (Community AWS VPC)
    - `Azure/compute/azurerm` (Microsoft's Azure Compute)
  EOT
}

# ========================================================================
# SECTION 2: SIMULATED REGISTRY MODULE PATTERNS
# ========================================================================

# This simulates what a production registry module call looks like
resource "local_file" "production_example" {
  filename = "./terraform-lab-output/production-module-examples.tf"
  content  = <<-EOT
    # ============================================
    # PRODUCTION MODULE USAGE EXAMPLES
    # ============================================
    # Copy these into real projects!

    # --- AWS VPC Module ---
    module "vpc" {
      source  = "terraform-aws-modules/vpc/aws"
      version = "~> 5.0"

      name = "production-vpc"
      cidr = "10.0.0.0/16"

      azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
      private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

      enable_nat_gateway = true
      single_nat_gateway = false

      tags = {
        Environment = "production"
        ManagedBy   = "terraform"
      }
    }

    # --- Azure Resource Group Module ---
    module "resource_group" {
      source  = "Azure/resource-group/azurerm"
      version = "~> 0.1"

      name     = "rg-production"
      location = "eastus"
      tags     = { environment = "production" }
    }

    # --- GKE Cluster Module ---
    module "gke" {
      source  = "terraform-google-modules/kubernetes-engine/google"
      version = "~> 29.0"

      project_id = "my-gcp-project"
      name       = "production-cluster"
      region     = "us-central1"

      node_pools = [
        {
          name         = "default-pool"
          machine_type = "e2-standard-4"
          min_count    = 1
          max_count    = 10
        }
      ]
    }
  EOT
}

# ========================================================================
# SECTION 3: MODULE EVALUATION CHECKLIST
# ========================================================================

resource "local_file" "evaluation_checklist" {
  filename = "./terraform-lab-output/module-evaluation-checklist.json"
  content  = jsonencode({
    title = "Module Evaluation Checklist"
    criteria = [
      {
        category = "Trust"
        checks = [
          "Is the module from a verified publisher?",
          "Does it have the 'Partner' or 'Official' badge?",
          "How many downloads does it have?",
          "Is the source code on GitHub/GitLab?"
        ]
      },
      {
        category = "Quality"
        checks = [
          "Are variables well-documented with descriptions?",
          "Does it include validation blocks?",
          "Are outputs clearly defined?",
          "Does it include examples/ directory?",
          "Are there tests (terratest, etc.)?"
        ]
      },
      {
        category = "Maintenance"
        checks = [
          "When was the last release?",
          "Are issues being responded to?",
          "Is there a CHANGELOG?",
          "Is there a clear upgrade path between versions?"
        ]
      },
      {
        category = "Security"
        checks = [
          "Does it follow least-privilege for IAM?",
          "Are secrets handled properly?",
          "Does it encrypt data at rest/in transit?",
          "Has it been audited?"
        ]
      }
    ]
  })
}

# ========================================================================
# SECTION 4: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-registry.ps1"
  content  = <<-EOT
    # PowerShell Gallery vs Terraform Registry
    # =========================================

    # Finding modules
    # Terraform: Browse registry.terraform.io
    # PowerShell:
    Find-Module -Name Az.Compute
    Find-Module -Tag "networking" -Repository PSGallery

    # Installing/using modules
    # Terraform: module { source = "org/name/provider"; version = "~> 1.0" }
    # PowerShell:
    Install-Module -Name Az.Network -RequiredVersion 6.0.0
    Import-Module Az.Network

    # Version management
    # Terraform: version = "~> 5.0" in module block
    # PowerShell:
    Get-InstalledModule -Name Az.Network -AllVersions
    Update-Module -Name Az.Network -RequiredVersion 6.1.0

    # Publishing
    # Terraform: Push to registry via GitHub + webhook
    # PowerShell:
    # Publish-Module -Name MyModule -NuGetApiKey $$apiKey

    Write-Host "Key Differences:" -ForegroundColor Yellow
    Write-Host "  Terraform Registry: Modules scoped per-project (.terraform/)"
    Write-Host "  PSGallery: Modules installed system-wide or per-user"
    Write-Host "  Terraform: Auto-downloaded on 'terraform init'"
    Write-Host "  PowerShell: Must run Install-Module explicitly"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "guide_path" {
  description = "Path to the registry usage guide"
  value       = local_file.registry_guide.filename
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    find_modules    = "Browse registry.terraform.io for community modules"
    evaluate        = "Check downloads, maintenance, badges, and code quality"
    version_pin     = "Always use version = \"~> X.0\" for stability"
    naming          = "Registry modules follow namespace/name/provider format"
  }
}
