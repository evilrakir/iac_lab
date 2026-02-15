# ╔════════════════════════════════════════════════════════════════════╗
# ║  WINDOWS INFRASTRUCTURE MODULES                                  ║
# ║  Creating reusable Terraform modules for Windows environments    ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise demonstrates how to build Terraform modules specifically
# for Windows infrastructure: IIS, AD, Windows services, and more.
# We use the local provider to generate configuration templates that
# you would use with real Windows providers in production.

# POWERSHELL COMPARISON:
# =====================
# Like PowerShell DSC Composite Resources - packaging multiple related
# resources into a single reusable unit.
# DSC: Configuration WebServer { Import-DscResource -ModuleName WebAdministration }
# Terraform: module "web_server" { source = "./windows-iis" }

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
  description = "Deployment environment"
  type        = string
  default     = "development"
}

variable "domain_name" {
  description = "Active Directory domain name"
  type        = string
  default     = "lab.local"
}

# ========================================================================
# SECTION 1: IIS WEB SERVER MODULE TEMPLATE
# ========================================================================

resource "local_file" "iis_module_main" {
  filename = "./terraform-lab-output/windows-modules/iis-module/main.tf"
  content  = <<-EOT
    # IIS Web Server Module
    # Usage: module "web" { source = "./iis-module"; site_name = "MyApp" }
    #
    # This module would use the Windows provider or provisioners to:
    # 1. Enable IIS Windows Feature
    # 2. Create application pool
    # 3. Create website with bindings
    # 4. Configure authentication
    # 5. Deploy web content

    variable "site_name" {
      description = "IIS website name"
      type        = string
    }

    variable "port" {
      description = "HTTP port"
      type        = number
      default     = 80
    }

    variable "app_pool_name" {
      description = "Application pool name"
      type        = string
      default     = ""  # Defaults to site_name if empty
    }

    variable "dotnet_version" {
      description = ".NET runtime version"
      type        = string
      default     = "v4.0"
      validation {
        condition     = contains(["v2.0", "v4.0", "No Managed Code"], var.dotnet_version)
        error_message = "Must be v2.0, v4.0, or No Managed Code."
      }
    }

    variable "content_path" {
      description = "Physical path for web content"
      type        = string
      default     = "C:\\inetpub\\wwwroot"
    }

    locals {
      pool_name = var.app_pool_name != "" ? var.app_pool_name : var.site_name
    }

    # In production, this would use provisioners or Windows-specific providers:
    #
    # resource "null_resource" "iis_setup" {
    #   provisioner "local-exec" {
    #     command     = "Install-WindowsFeature Web-Server -IncludeManagementTools"
    #     interpreter = ["PowerShell", "-Command"]
    #   }
    # }
    #
    # For now, we generate the equivalent PowerShell DSC configuration:

    output "dsc_configuration" {
      value = <<-DSC
        Configuration IIS_$${var.site_name} {
          Import-DscResource -ModuleName WebAdministration

          WindowsFeature IIS {
            Name   = 'Web-Server'
            Ensure = 'Present'
          }

          xWebAppPool $${local.pool_name} {
            Name                  = '$${local.pool_name}'
            State                 = 'Started'
            managedRuntimeVersion = '$${var.dotnet_version}'
          }

          xWebsite $${var.site_name} {
            Name            = '$${var.site_name}'
            PhysicalPath    = '$${var.content_path}'
            ApplicationPool = '$${local.pool_name}'
            BindingInfo     = MSFT_xWebBindingInformation {
              Protocol = 'HTTP'
              Port     = $${var.port}
            }
          }
        }
      DSC
    }
  EOT
}

# ========================================================================
# SECTION 2: ACTIVE DIRECTORY MODULE TEMPLATE
# ========================================================================

resource "local_file" "ad_module" {
  filename = "./terraform-lab-output/windows-modules/ad-module/main.tf"
  content  = <<-EOT
    # Active Directory Module
    # Usage: module "ad" { source = "./ad-module"; ou_name = "Servers" }
    #
    # This module manages AD resources using the AD provider

    variable "ou_name" {
      description = "Organizational Unit name"
      type        = string
    }

    variable "ou_path" {
      description = "Parent OU path"
      type        = string
      default     = "DC=lab,DC=local"
    }

    variable "groups" {
      description = "Security groups to create in this OU"
      type = list(object({
        name        = string
        scope       = string  # DomainLocal, Global, Universal
        description = string
      }))
      default = []
    }

    variable "service_accounts" {
      description = "Service accounts to create"
      type = list(object({
        name        = string
        description = string
      }))
      default = []
    }

    # In production with the AD provider:
    # resource "ad_ou" "this" {
    #   name = var.ou_name
    #   path = var.ou_path
    # }
    #
    # resource "ad_group" "groups" {
    #   for_each    = { for g in var.groups : g.name => g }
    #   name        = each.value.name
    #   sam_account_name = each.value.name
    #   scope       = each.value.scope
    #   container   = ad_ou.this.dn
    # }

    output "ou_dn" {
      value = "OU=$${var.ou_name},$${var.ou_path}"
    }
  EOT
}

# ========================================================================
# SECTION 3: WINDOWS SERVICE MODULE TEMPLATE
# ========================================================================

resource "local_file" "service_module" {
  filename = "./terraform-lab-output/windows-modules/service-module/main.tf"
  content  = <<-EOT
    # Windows Service Module
    # Manages Windows services via Terraform

    variable "service_name" {
      description = "Windows service name"
      type        = string
    }

    variable "display_name" {
      description = "Service display name"
      type        = string
    }

    variable "executable_path" {
      description = "Path to service executable"
      type        = string
    }

    variable "startup_type" {
      description = "Service startup type"
      type        = string
      default     = "Automatic"
      validation {
        condition = contains(
          ["Automatic", "Manual", "Disabled", "AutomaticDelayedStart"],
          var.startup_type
        )
        error_message = "Invalid startup type."
      }
    }

    variable "run_as_account" {
      description = "Service account (LocalSystem, NetworkService, or domain account)"
      type        = string
      default     = "LocalSystem"
    }

    variable "depends_on_services" {
      description = "Services this service depends on"
      type        = list(string)
      default     = []
    }

    # PowerShell equivalent:
    # New-Service -Name $service_name -BinaryPathName $executable_path `
    #   -DisplayName $display_name -StartupType $startup_type

    output "service_config" {
      value = {
        name         = var.service_name
        display_name = var.display_name
        executable   = var.executable_path
        startup_type = var.startup_type
        run_as       = var.run_as_account
        depends_on   = var.depends_on_services
      }
    }
  EOT
}

# ========================================================================
# SECTION 4: COMPARISON AND USAGE PATTERNS
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-windows-modules.ps1"
  content  = <<-EOT
    # Windows Infrastructure: Terraform Modules vs PowerShell DSC
    # ============================================================

    # TERRAFORM MODULES          | POWERSHELL DSC
    # ---------------------------|------------------------------
    # module "web" { ... }       | Configuration WebServer { }
    # variables.tf               | param() block in configuration
    # outputs.tf                 | Return values (less common)
    # source = "./module"        | Import-DscResource
    # terraform apply            | Start-DscConfiguration
    # terraform.tfstate          | MOF files

    # Example: IIS with PowerShell DSC
    Configuration WebServer {
        param(
            [string]$$SiteName = "Default Web Site",
            [int]$$Port = 80
        )

        Import-DscResource -ModuleName WebAdministration

        WindowsFeature IIS {
            Name   = 'Web-Server'
            Ensure = 'Present'
        }

        xWebsite $$SiteName {
            Name         = $$SiteName
            PhysicalPath = "C:\inetpub\wwwroot"
            BindingInfo  = @(
                MSFT_xWebBindingInformation {
                    Protocol = 'HTTP'
                    Port     = $$Port
                }
            )
        }
    }

    # Example: Same with Terraform module call
    # module "web_server" {
    #   source    = "./iis-module"
    #   site_name = "Default Web Site"
    #   port      = 80
    # }

    Write-Host "Key Insight:" -ForegroundColor Yellow
    Write-Host "  Terraform modules and DSC configurations solve the same problem"
    Write-Host "  - both create reusable, parameterized infrastructure definitions"
    Write-Host "  Terraform adds: state tracking, plan/preview, multi-provider support"
  EOT
}

# Summary config showing how modules fit together
resource "local_file" "architecture_diagram" {
  filename = "./terraform-lab-output/windows-modules/architecture.json"
  content  = jsonencode({
    title = "Windows Infrastructure Module Architecture"
    modules = {
      "iis-module"     = "Web server provisioning (IIS features, sites, pools)"
      "ad-module"      = "Active Directory (OUs, groups, service accounts)"
      "service-module" = "Windows services (install, configure, dependencies)"
    }
    usage = "Each module is called from a root configuration with environment-specific variables"
    pattern = "Root config -> Environment vars -> Module calls -> Windows resources"
  })
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "generated_modules" {
  description = "Paths to generated module templates"
  value = {
    iis_module     = local_file.iis_module_main.filename
    ad_module      = local_file.ad_module.filename
    service_module = local_file.service_module.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    pattern         = "Package Windows resources into reusable modules"
    iis             = "Use modules to standardize IIS deployments across teams"
    active_directory = "Manage AD OUs, groups, and accounts as code"
    services        = "Declare Windows services with dependencies and startup config"
    dsc_comparison  = "Terraform modules are analogous to DSC Composite Resources"
  }
}
