# ╔════════════════════════════════════════════════════════════════════╗
# ║  GOOGLE CLOUD PROVIDER BASICS                                    ║
# ║  Understanding the Google Cloud Platform (GCP) provider          ║
# ╚════════════════════════════════════════════════════════════════════╝

# Google Cloud takes a different approach to resource organization than
# Azure or AWS. Projects are the fundamental container, and IAM is
# managed at multiple levels. This exercise generates reference configs
# to learn GCP patterns without needing a GCP account.

# POWERSHELL COMPARISON:
# =====================
# GCP uses gcloud CLI (similar to az CLI in Azure):
#   gcloud compute instances create my-vm --zone us-central1-a
# Terraform wraps these into declarative, tracked infrastructure.

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

variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "my-project-123456"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment label"
  type        = string
  default     = "dev"
}

# ========================================================================
# SECTION 1: PROVIDER CONFIGURATION
# ========================================================================

resource "local_file" "provider_config" {
  filename = "./terraform-lab-output/gcp-basics/provider-configuration.tf"
  content  = <<-EOT
    # ============================================
    # GCP PROVIDER CONFIGURATION
    # ============================================

    terraform {
      required_providers {
        google = {
          source  = "hashicorp/google"
          version = "~> 5.0"
        }
      }
    }

    # --- Method 1: gcloud CLI Authentication (Dev) ---
    # First run: gcloud auth application-default login
    provider "google" {
      project = "${var.project_id}"
      region  = "${var.region}"
      zone    = "${var.zone}"
    }

    # --- Method 2: Service Account Key File ---
    # provider "google" {
    #   project     = "my-project-id"
    #   region      = "us-central1"
    #   credentials = file("service-account-key.json")
    # }

    # --- Method 3: Environment Variable ---
    # export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
    # export GOOGLE_PROJECT="my-project-id"
    # provider "google" {
    #   region = "us-central1"
    # }

    # --- Method 4: Workload Identity (GKE / Cloud Run) ---
    # provider "google" {
    #   project = "my-project-id"
    #   region  = "us-central1"
    #   # Automatically uses workload identity
    # }

    # GCP KEY CONCEPT: Projects
    # ========================
    # Unlike AWS (accounts) or Azure (subscriptions + resource groups),
    # GCP uses "projects" as the primary organizational unit.
    # All resources belong to a project.
    # Projects belong to folders, which belong to an organization.
  EOT
}

# ========================================================================
# SECTION 2: CORE GCP RESOURCES
# ========================================================================

resource "local_file" "core_resources" {
  filename = "./terraform-lab-output/gcp-basics/core-resources.tf"
  content  = <<-EOT
    # ============================================
    # CORE GCP RESOURCES IN TERRAFORM
    # ============================================

    # --- VPC Network ---
    # GCP VPCs are global (not regional like AWS/Azure)
    # gcloud equivalent: gcloud compute networks create my-vpc
    resource "google_compute_network" "main" {
      name                    = "myapp-${var.environment}-vpc"
      auto_create_subnetworks = false  # Custom mode for control
      project                 = "${var.project_id}"
    }

    # --- Subnets ---
    # Subnets are regional (the network is global)
    resource "google_compute_subnetwork" "web" {
      name          = "myapp-${var.environment}-web-subnet"
      ip_cidr_range = "10.0.1.0/24"
      region        = "${var.region}"
      network       = google_compute_network.main.id

      # GCP-specific: Secondary ranges for GKE pods/services
      # secondary_ip_range {
      #   range_name    = "pods"
      #   ip_cidr_range = "10.1.0.0/16"
      # }
    }

    # --- Firewall Rules ---
    # GCP uses network-level firewall rules (not per-subnet)
    # gcloud equivalent: gcloud compute firewall-rules create allow-http ...
    resource "google_compute_firewall" "allow_http" {
      name    = "myapp-${var.environment}-allow-http"
      network = google_compute_network.main.name

      allow {
        protocol = "tcp"
        ports    = ["80", "443"]
      }

      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["web-server"]  # Only applies to VMs with this tag
    }

    resource "google_compute_firewall" "allow_ssh" {
      name    = "myapp-${var.environment}-allow-ssh"
      network = google_compute_network.main.name

      allow {
        protocol = "tcp"
        ports    = ["22"]
      }

      source_ranges = ["10.0.0.0/8"]  # Internal only
      target_tags   = ["ssh-enabled"]
    }

    # --- Cloud Storage Bucket ---
    # gcloud equivalent: gsutil mb gs://my-bucket
    resource "google_storage_bucket" "assets" {
      name          = "${var.project_id}-${var.environment}-assets"
      location      = "US"
      force_destroy = var.environment != "production"

      uniform_bucket_level_access = true

      versioning {
        enabled = true
      }

      lifecycle_rule {
        condition {
          age = 90
        }
        action {
          type          = "SetStorageClass"
          storage_class = "NEARLINE"
        }
      }
    }

    # --- Compute Instance ---
    # gcloud equivalent: gcloud compute instances create my-vm
    resource "google_compute_instance" "web" {
      name         = "myapp-${var.environment}-web"
      machine_type = "e2-medium"
      zone         = "${var.zone}"
      tags         = ["web-server", "ssh-enabled"]

      boot_disk {
        initialize_params {
          image = "debian-cloud/debian-11"
          size  = 20
        }
      }

      network_interface {
        subnetwork = google_compute_subnetwork.web.id
        access_config {
          # Ephemeral public IP
        }
      }

      metadata_startup_script = "apt-get update && apt-get install -y nginx"

      labels = {
        environment = "${var.environment}"
        managed_by  = "terraform"
      }
    }
  EOT
}

# ========================================================================
# SECTION 3: GCP vs AWS vs AZURE COMPARISON
# ========================================================================

resource "local_file" "cloud_comparison" {
  filename = "./terraform-lab-output/gcp-basics/cloud-provider-comparison.json"
  content = jsonencode({
    title = "Cloud Provider Terraform Resource Comparison"
    comparison = {
      compute = {
        aws   = "aws_instance"
        azure = "azurerm_linux_virtual_machine"
        gcp   = "google_compute_instance"
        note  = "GCP uses machine_type (e2-medium), AWS uses instance_type (t3.medium)"
      }
      networking = {
        vpc = {
          aws   = "aws_vpc (regional)"
          azure = "azurerm_virtual_network (regional)"
          gcp   = "google_compute_network (GLOBAL)"
        }
        subnet = {
          aws   = "aws_subnet (AZ-specific)"
          azure = "azurerm_subnet (VNet-scoped)"
          gcp   = "google_compute_subnetwork (regional)"
        }
        firewall = {
          aws   = "aws_security_group (instance-level)"
          azure = "azurerm_network_security_group (subnet-level)"
          gcp   = "google_compute_firewall (network-level, tag-based)"
        }
      }
      storage = {
        object_storage = {
          aws   = "aws_s3_bucket"
          azure = "azurerm_storage_account + azurerm_storage_container"
          gcp   = "google_storage_bucket"
        }
      }
      database = {
        managed_sql = {
          aws   = "aws_db_instance (RDS)"
          azure = "azurerm_mssql_server + azurerm_mssql_database"
          gcp   = "google_sql_database_instance"
        }
      }
      kubernetes = {
        aws   = "aws_eks_cluster"
        azure = "azurerm_kubernetes_cluster"
        gcp   = "google_container_cluster (GKE)"
      }
      organization = {
        aws   = "Account → Region → VPC"
        azure = "Subscription → Resource Group → Resources"
        gcp   = "Organization → Folder → Project → Resources"
      }
    }
    gcp_unique_features = [
      "VPC networks are global (subnets are regional)",
      "Firewall rules use network tags for targeting",
      "Projects as primary organizational unit",
      "Preemptible VMs (like AWS Spot, very cheap)",
      "Live migration - VMs don't go down for maintenance",
      "Per-second billing on compute instances"
    ]
  })
}

# ========================================================================
# SECTION 4: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-gcp.ps1"
  content  = <<-EOT
    # GCP: Terraform vs CLI/PowerShell Approaches
    # =============================================

    # TERRAFORM                        | GCLOUD CLI
    # ---------------------------------|-------------------------------
    # google_compute_network           | gcloud compute networks create
    # google_compute_instance          | gcloud compute instances create
    # google_compute_firewall          | gcloud compute firewall-rules create
    # google_storage_bucket            | gsutil mb gs://bucket-name
    # google_sql_database_instance     | gcloud sql instances create
    # google_container_cluster         | gcloud container clusters create
    # terraform plan (preview)         | --dry-run (limited support)
    # terraform destroy                | gcloud ... delete

    # NOTE: GCP doesn't have an official PowerShell module like Azure.
    # Instead, GCP uses:
    #   1. gcloud CLI (primary tool)
    #   2. Cloud Client Libraries (Python, Go, Java, Node.js)
    #   3. REST API directly
    #
    # PowerShell users can still use gcloud from PowerShell:

    # gcloud CLI from PowerShell:
    # gcloud compute instances list --format=json | ConvertFrom-Json
    # gcloud compute instances create "myapp-web" ``
    #   --zone "us-central1-a" ``
    #   --machine-type "e2-medium" ``
    #   --image-family "debian-11" ``
    #   --image-project "debian-cloud"

    # Or use Google Cloud PowerShell cmdlets (community):
    # Install-Module GoogleCloud
    # Get-GceInstance -Project "my-project"

    Write-Host "GCP: Terraform vs gcloud CLI" -ForegroundColor Yellow
    Write-Host "  gcloud CLI: Imperative, command-based management"
    Write-Host "  Terraform:  Declarative, state-tracked management"
    Write-Host ""
    Write-Host "  GCP Unique Concepts:" -ForegroundColor Cyan
    Write-Host "  - Projects (not subscriptions or accounts)"
    Write-Host "  - Global VPCs with regional subnets"
    Write-Host "  - Tag-based firewall rules"
    Write-Host "  - Labels instead of Tags (same concept)"
    Write-Host ""
    Write-Host "  For Windows admins:" -ForegroundColor Green
    Write-Host "  - Use gcloud CLI from PowerShell (works great)"
    Write-Host "  - Terraform abstracts the differences between clouds"
    Write-Host "  - Same HCL patterns work for AWS, Azure, AND GCP"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "gcp_resources" {
  description = "Generated GCP reference files"
  value = {
    provider_config  = local_file.provider_config.filename
    core_resources   = local_file.core_resources.filename
    cloud_comparison = local_file.cloud_comparison.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    provider_setup = "GCP provider needs project, region, and zone configured"
    authentication = "Use gcloud auth for dev, service account keys or workload identity for CI/CD"
    global_vpc     = "GCP VPCs are global (unlike AWS/Azure regional VPCs)"
    tags_vs_labels = "GCP uses 'labels' on resources and 'tags' for firewall targeting"
    projects       = "GCP organizes by Project → Folder → Organization (not resource groups)"
    multi_cloud    = "Terraform uses the same HCL syntax across all three major clouds"
  }
}
