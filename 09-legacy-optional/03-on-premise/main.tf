# ╔════════════════════════════════════════════════════════════════════╗
# ║  ON-PREMISE INFRASTRUCTURE (LEGACY)                             ║
# ║  Managing VMware, Hyper-V, and hybrid infrastructure            ║
# ╚════════════════════════════════════════════════════════════════════╝

# Terraform isn't just for cloud - it can manage on-premise infrastructure
# too. VMware vSphere, Nutanix, and even Hyper-V can be managed with
# Terraform providers. This is especially valuable for organizations
# migrating from on-prem to cloud (hybrid infrastructure).

# POWERSHELL COMPARISON:
# =====================
# Windows admins already manage on-prem with PowerShell:
#   New-VM -Name "WebServer" -MemoryStartupBytes 4GB -SwitchName "Production"
# Terraform adds state tracking and declarative management:
#   resource "vsphere_virtual_machine" "web" { name = "WebServer" ... }

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

variable "datacenter" {
  description = "On-premise datacenter name"
  type        = string
  default     = "DC-PRIMARY"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "production"
}

variable "vm_specs" {
  description = "VM specifications for on-premise workloads"
  type = map(object({
    cpus      = number
    memory_gb = number
    disk_gb   = number
    os        = string
  }))
  default = {
    web = {
      cpus      = 4
      memory_gb = 8
      disk_gb   = 100
      os        = "Windows Server 2022"
    }
    app = {
      cpus      = 8
      memory_gb = 16
      disk_gb   = 200
      os        = "Windows Server 2022"
    }
    db = {
      cpus      = 16
      memory_gb = 64
      disk_gb   = 500
      os        = "Windows Server 2022"
    }
  }
}

# ========================================================================
# SECTION 1: VMWARE VSPHERE PROVIDER
# ========================================================================

resource "local_file" "vsphere_config" {
  filename = "./terraform-lab-output/on-premise/vsphere-configuration.tf"
  content  = <<-EOT
    # ============================================
    # VMWARE VSPHERE WITH TERRAFORM
    # ============================================

    terraform {
      required_providers {
        vsphere = {
          source  = "hashicorp/vsphere"
          version = "~> 2.5"
        }
      }
    }

    # --- Provider Configuration ---
    # PS Equivalent: Connect-VIServer -Server vcenter.example.com
    provider "vsphere" {
      user                 = var.vsphere_user
      password             = var.vsphere_password
      vsphere_server       = "vcenter.example.com"
      allow_unverified_ssl = false
    }

    # --- Data Sources (existing infrastructure) ---
    data "vsphere_datacenter" "dc" {
      name = "${var.datacenter}"
    }

    data "vsphere_compute_cluster" "cluster" {
      name          = "Production-Cluster"
      datacenter_id = data.vsphere_datacenter.dc.id
    }

    data "vsphere_datastore" "datastore" {
      name          = "SAN-PROD-01"
      datacenter_id = data.vsphere_datacenter.dc.id
    }

    data "vsphere_network" "network" {
      name          = "VM-Production-VLAN100"
      datacenter_id = data.vsphere_datacenter.dc.id
    }

    data "vsphere_virtual_machine" "template" {
      name          = "template-windows2022"
      datacenter_id = data.vsphere_datacenter.dc.id
    }

    # --- Virtual Machine ---
    # PS Equivalent: New-VM -Template "template-windows2022" -VMHost ...
    resource "vsphere_virtual_machine" "web" {
      name             = "WEB-PROD-01"
      resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
      datastore_id     = data.vsphere_datastore.datastore.id
      folder           = "Production/WebServers"

      num_cpus = ${var.vm_specs.web.cpus}
      memory   = ${var.vm_specs.web.memory_gb * 1024}
      guest_id = data.vsphere_virtual_machine.template.guest_id

      network_interface {
        network_id   = data.vsphere_network.network.id
        adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
      }

      disk {
        label            = "disk0"
        size             = ${var.vm_specs.web.disk_gb}
        eagerly_scrub    = false
        thin_provisioned = true
      }

      clone {
        template_uuid = data.vsphere_virtual_machine.template.id

        customize {
          windows_options {
            computer_name  = "WEB-PROD-01"
            admin_password = var.admin_password
            join_domain    = "corp.example.com"
            domain_admin_user     = var.domain_join_user
            domain_admin_password = var.domain_join_password
          }

          network_interface {
            ipv4_address = "10.100.1.10"
            ipv4_netmask = 24
          }

          ipv4_gateway    = "10.100.1.1"
          dns_server_list = ["10.100.0.10", "10.100.0.11"]
        }
      }
    }
  EOT
}

# ========================================================================
# SECTION 2: HYPER-V PATTERNS
# ========================================================================

resource "local_file" "hyperv_patterns" {
  filename = "./terraform-lab-output/on-premise/hyperv-terraform-patterns.tf"
  content  = <<-EOT
    # ============================================
    # HYPER-V WITH TERRAFORM
    # ============================================

    # NOTE: No official Hyper-V provider exists. Options:
    # 1. Community provider (github.com/taliesins/terraform-provider-hyperv)
    # 2. null_resource + PowerShell (most common approach)
    # 3. Azure Stack HCI (for newer environments)

    # --- Pattern 1: Community Hyper-V Provider ---
    # terraform {
    #   required_providers {
    #     hyperv = {
    #       source  = "taliesins/hyperv"
    #       version = "~> 1.0"
    #     }
    #   }
    # }
    #
    # provider "hyperv" {
    #   user     = var.hyperv_user
    #   password = var.hyperv_password
    #   host     = "hyperv01.corp.example.com"
    #   port     = 5986
    #   https    = true
    # }
    #
    # resource "hyperv_machine_instance" "web" {
    #   name                   = "WEB-PROD-01"
    #   generation             = 2
    #   processor_count        = 4
    #   dynamic_memory         = true
    #   memory_startup_bytes   = 4294967296  # 4GB
    #   memory_maximum_bytes   = 8589934592  # 8GB
    #   wait_for_state_timeout = 10
    #   state                  = "Running"
    # }

    # --- Pattern 2: null_resource + PowerShell (Practical) ---
    resource "null_resource" "hyperv_vm" {
      provisioner "local-exec" {
        command     = <<-PS
          $$ErrorActionPreference = "Stop"

          # Check if VM exists
          $$vm = Get-VM -Name "WEB-PROD-01" -ErrorAction SilentlyContinue
          if ($$vm) {
            Write-Host "VM already exists, updating..."
            Set-VM -Name "WEB-PROD-01" -ProcessorCount 4 -MemoryStartupBytes 4GB
          } else {
            Write-Host "Creating new VM..."
            New-VM -Name "WEB-PROD-01" `
              -MemoryStartupBytes 4GB `
              -NewVHDPath "D:\\VMs\\WEB-PROD-01\\disk0.vhdx" `
              -NewVHDSizeBytes 100GB `
              -SwitchName "Production" `
              -Generation 2

            Set-VM -Name "WEB-PROD-01" -ProcessorCount 4 -DynamicMemory
            Start-VM -Name "WEB-PROD-01"
          }
        PS
        interpreter = ["PowerShell", "-Command"]
      }

      provisioner "local-exec" {
        when    = destroy
        command = <<-PS
          Stop-VM -Name "WEB-PROD-01" -Force -ErrorAction SilentlyContinue
          Remove-VM -Name "WEB-PROD-01" -Force -ErrorAction SilentlyContinue
        PS
        interpreter = ["PowerShell", "-Command"]
      }
    }
  EOT
}

# ========================================================================
# SECTION 3: HYBRID CLOUD PATTERNS
# ========================================================================

resource "local_file" "hybrid_patterns" {
  filename = "./terraform-lab-output/on-premise/hybrid-cloud-patterns.json"
  content = jsonencode({
    title = "Hybrid Infrastructure with Terraform"
    patterns = {
      extend_to_cloud = {
        description = "Keep existing on-prem, add cloud for new workloads"
        terraform_approach = "Separate state files per environment (on-prem vs cloud)"
        example = "On-prem AD + DNS, cloud web tier + CDN"
        connectivity = "VPN or ExpressRoute/Direct Connect"
      }
      burst_to_cloud = {
        description = "On-prem for baseline, cloud for peak demand"
        terraform_approach = "Auto-scaling groups in cloud, static on-prem"
        example = "On-prem app servers + cloud auto-scaling group"
        connectivity = "Site-to-site VPN with shared database"
      }
      disaster_recovery = {
        description = "Primary on-prem, DR in cloud"
        terraform_approach = "Terraform manages cloud DR environment"
        example = "On-prem production + cloud warm standby"
        connectivity = "Database replication + DNS failover"
      }
      lift_and_shift = {
        description = "Migrate VMs from on-prem to cloud"
        terraform_approach = "terraform import existing cloud resources after migration"
        example = "VMware VMs -> Azure VMs using Azure Migrate"
        tools = ["Azure Migrate", "AWS Application Migration Service", "Terraform import"]
      }
    }
    multi_provider_example = {
      description = "Single Terraform config managing both on-prem and cloud"
      providers = ["vsphere (on-prem VMs)", "azurerm (Azure resources)", "dns (shared DNS)"]
      benefits = [
        "Single view of all infrastructure",
        "Consistent naming and tagging",
        "Coordinated deployments across environments",
        "Unified CI/CD pipeline"
      ]
    }
  })
}

# ========================================================================
# SECTION 4: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-on-premise.ps1"
  content  = <<-EOT
    # On-Premise Infrastructure: Terraform vs PowerShell
    # ====================================================

    # TERRAFORM (vSphere)              | POWERSHELL (Hyper-V / VMware)
    # ---------------------------------|-------------------------------
    # vsphere_virtual_machine          | New-VM (Hyper-V) / New-VM (PowerCLI)
    # vsphere_host                     | Get-VMHost (PowerCLI)
    # vsphere_datastore                | Get-Datastore (PowerCLI)
    # vsphere_network                  | Get-VirtualSwitch
    # terraform state (tracked)        | No state (script output only)
    # terraform plan (preview)         | -WhatIf (limited)
    # terraform destroy (cleanup)      | Remove-VM (manual)

    # PowerShell: Hyper-V VM management
    # $$vm = New-VM -Name "WEB01" `
    #   -MemoryStartupBytes 4GB `
    #   -NewVHDPath "D:\VMs\WEB01\disk.vhdx" `
    #   -NewVHDSizeBytes 100GB `
    #   -SwitchName "Production" `
    #   -Generation 2
    #
    # Set-VM -VM $$vm -ProcessorCount 4 -DynamicMemory
    # Set-VMFirmware -VM $$vm -FirstBootDevice (Get-VMDvdDrive -VM $$vm)
    # Start-VM -VM $$vm

    # PowerShell: VMware PowerCLI
    # Connect-VIServer -Server vcenter.example.com
    # New-VM -Name "WEB01" `
    #   -Template "template-win2022" `
    #   -VMHost "esxi01.example.com" `
    #   -Datastore "SAN-01" `
    #   -DiskGB 100 `
    #   -MemoryGB 4 `
    #   -NumCpu 4

    Write-Host "On-Premise: Terraform vs PowerShell" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  PowerShell Strengths:" -ForegroundColor Green
    Write-Host "    - Native Hyper-V management (built-in cmdlets)"
    Write-Host "    - VMware PowerCLI (mature, full-featured)"
    Write-Host "    - Quick ad-hoc VM creation and management"
    Write-Host "    - Deep OS-level control"
    Write-Host ""
    Write-Host "  Terraform Strengths:" -ForegroundColor Cyan
    Write-Host "    - State tracking (knows what VMs exist)"
    Write-Host "    - Plan before apply (preview changes)"
    Write-Host "    - Same tool for on-prem AND cloud"
    Write-Host "    - Reproducible environments from code"
    Write-Host ""
    Write-Host "  Hybrid Recommendation:" -ForegroundColor Magenta
    Write-Host "    - Terraform for VM lifecycle (create/destroy)"
    Write-Host "    - PowerShell for operations (monitor/troubleshoot)"
    Write-Host "    - Both tools in CI/CD for full automation"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "onprem_resources" {
  description = "Generated on-premise reference files"
  value = {
    vsphere_config  = local_file.vsphere_config.filename
    hyperv_patterns = local_file.hyperv_patterns.filename
    hybrid_patterns = local_file.hybrid_patterns.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    vsphere        = "hashicorp/vsphere provider manages VMware infrastructure as code"
    hyperv         = "Hyper-V can be managed via community provider or null_resource + PowerShell"
    hybrid         = "Terraform manages both on-prem and cloud in one workflow"
    migration      = "Use Terraform import after migrating VMs to cloud"
    powershell     = "PowerShell remains essential for Windows on-prem operations"
    best_practice  = "Same Terraform patterns work on-prem (vSphere) and cloud (AWS/Azure/GCP)"
  }
}
