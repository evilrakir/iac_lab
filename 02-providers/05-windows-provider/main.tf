# ╔════════════════════════════════════════════════════════════════════╗
# ║  WINDOWS PROVIDER CONFIGURATION                                  ║
# ║  Managing Windows infrastructure with Terraform                  ║
# ╚════════════════════════════════════════════════════════════════════╝

# Windows administrators have several Terraform providers for managing
# on-premise and hybrid Windows infrastructure: Active Directory, DNS,
# DHCP, and WinRM-based management. This exercise shows how Terraform
# can replace many DSC and Group Policy configurations.

# POWERSHELL COMPARISON:
# =====================
# PowerShell DSC:  Configuration { Node "Server01" { WindowsFeature IIS { ... } } }
# Terraform:       resource "ad_computer" "server01" { name = "Server01" }
# Key insight:     Terraform manages infrastructure STATE, DSC manages OS CONFIG

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

variable "domain_name" {
  description = "Active Directory domain name"
  type        = string
  default     = "corp.example.com"
}

variable "domain_netbios" {
  description = "NetBIOS domain name"
  type        = string
  default     = "CORP"
}

variable "ou_structure" {
  description = "Organizational Unit structure"
  type = map(object({
    path        = string
    description = string
  }))
  default = {
    servers = {
      path        = "OU=Servers"
      description = "Server computer accounts"
    }
    workstations = {
      path        = "OU=Workstations"
      description = "Workstation computer accounts"
    }
    service_accounts = {
      path        = "OU=ServiceAccounts"
      description = "Service and application accounts"
    }
    groups = {
      path        = "OU=Groups"
      description = "Security and distribution groups"
    }
  }
}

# ========================================================================
# SECTION 1: WINDOWS TERRAFORM PROVIDERS
# ========================================================================

resource "local_file" "windows_providers" {
  filename = "./terraform-lab-output/windows-provider/windows-providers-guide.tf"
  content  = <<-EOT
    # ============================================
    # WINDOWS-SPECIFIC TERRAFORM PROVIDERS
    # ============================================

    # --- 1. Active Directory Provider ---
    # Manages AD objects: users, groups, computers, OUs, GPO links
    terraform {
      required_providers {
        ad = {
          source  = "hashicorp/ad"
          version = "~> 0.5"
        }
      }
    }

    provider "ad" {
      winrm_hostname = "dc01.${var.domain_name}"
      winrm_username = "$${var.domain_netbios}\\tf-admin"
      winrm_password = var.ad_admin_password
      winrm_port     = 5986
      winrm_proto    = "https"
      winrm_insecure = false
    }

    # --- 2. Windows DNS Provider ---
    # Manages DNS zones and records on Windows DNS Server
    # terraform {
    #   required_providers {
    #     dns = {
    #       source  = "hashicorp/dns"
    #       version = "~> 3.3"
    #     }
    #     windns = {
    #       source  = "portofportland/windns"
    #       version = "~> 0.3"
    #     }
    #   }
    # }

    # provider "windns" {
    #   server   = "dc01.${var.domain_name}"
    #   username = "$${var.domain_netbios}\\tf-admin"
    #   password = var.dns_admin_password
    # }

    # --- 3. Windows Remote (WinRM) for Custom Resources ---
    # Use null_resource with local-exec provisioner + PowerShell
    # for Windows operations not covered by providers
    # resource "null_resource" "configure_iis" {
    #   provisioner "local-exec" {
    #     command     = "Invoke-Command -ComputerName server01 -ScriptBlock { Install-WindowsFeature Web-Server }"
    #     interpreter = ["PowerShell", "-Command"]
    #   }
    # }
  EOT
}

# ========================================================================
# SECTION 2: ACTIVE DIRECTORY MANAGEMENT
# ========================================================================

resource "local_file" "ad_management" {
  filename = "./terraform-lab-output/windows-provider/active-directory.tf"
  content  = <<-EOT
    # ============================================
    # ACTIVE DIRECTORY WITH TERRAFORM
    # ============================================
    # Replace manual AD Users & Computers with code!

    # --- Organizational Units ---
    # PS Equivalent: New-ADOrganizationalUnit -Name "Servers" -Path "DC=corp,DC=example,DC=com"
    resource "ad_ou" "servers" {
      name = "Servers"
      path = "DC=corp,DC=example,DC=com"
      description = "Server computer accounts managed by Terraform"
      protected   = true  # Prevent accidental deletion
    }

    resource "ad_ou" "service_accounts" {
      name = "ServiceAccounts"
      path = "DC=corp,DC=example,DC=com"
      description = "Service accounts managed by Terraform"
      protected   = true
    }

    # --- Groups ---
    # PS Equivalent: New-ADGroup -Name "SG-WebAdmins" -GroupScope Global
    resource "ad_group" "web_admins" {
      name             = "SG-WebAdmins"
      sam_account_name = "SG-WebAdmins"
      scope            = "global"
      category         = "security"
      container        = ad_ou.servers.dn
      description      = "Web server administrators"
    }

    resource "ad_group" "db_admins" {
      name             = "SG-DBAdmins"
      sam_account_name = "SG-DBAdmins"
      scope            = "global"
      category         = "security"
      container        = ad_ou.servers.dn
      description      = "Database administrators"
    }

    # --- Service Accounts ---
    # PS Equivalent: New-ADUser -Name "svc-webapp" -AccountPassword $securePass
    resource "ad_user" "svc_webapp" {
      display_name     = "SVC-WebApp"
      principal_name   = "svc-webapp@${var.domain_name}"
      sam_account_name = "svc-webapp"
      container        = ad_ou.service_accounts.dn
      password_never_expires = false
      cannot_change_password = true
      enabled          = true
      initial_password = var.service_account_password  # From Vault!
    }

    # --- Computer Accounts ---
    # PS Equivalent: New-ADComputer -Name "WEB01" -Path "OU=Servers,..."
    resource "ad_computer" "web_servers" {
      for_each = toset(["WEB01", "WEB02", "WEB03"])

      name      = each.key
      container = ad_ou.servers.dn
      description = "Web server managed by Terraform"
    }

    # --- Group Membership ---
    # PS Equivalent: Add-ADGroupMember -Identity "SG-WebAdmins" -Members "svc-webapp"
    resource "ad_group_membership" "web_admin_members" {
      group_id     = ad_group.web_admins.id
      group_members = [
        ad_user.svc_webapp.dn,
      ]
    }
  EOT
}

# ========================================================================
# SECTION 3: DNS AND DHCP MANAGEMENT
# ========================================================================

resource "local_file" "dns_dhcp" {
  filename = "./terraform-lab-output/windows-provider/dns-dhcp-management.tf"
  content  = <<-EOT
    # ============================================
    # WINDOWS DNS MANAGEMENT WITH TERRAFORM
    # ============================================

    # --- A Records ---
    # PS Equivalent: Add-DnsServerResourceRecordA -Name "web01" -ZoneName "corp.example.com" -IPv4Address "10.0.1.10"
    resource "windns_record" "web_servers" {
      for_each = {
        web01 = "10.0.1.10"
        web02 = "10.0.1.11"
        web03 = "10.0.1.12"
      }

      record_name = each.key
      record_type = "A"
      zone_name   = "${var.domain_name}"
      ipv4address = each.value
    }

    # --- CNAME Records ---
    # PS Equivalent: Add-DnsServerResourceRecordCName -Name "www" -HostNameAlias "web01.corp.example.com"
    resource "windns_record" "www" {
      record_name = "www"
      record_type = "CNAME"
      zone_name   = "${var.domain_name}"
      hostnamealias = "web01.${var.domain_name}"
    }

    # --- SRV Records ---
    resource "windns_record" "sip" {
      record_name = "_sip._tcp"
      record_type = "SRV"
      zone_name   = "${var.domain_name}"
      domainname  = "sipserver.${var.domain_name}"
      priority    = 0
      weight      = 0
      port        = 5060
    }

    # ============================================
    # WINDOWS DHCP (via null_resource + PowerShell)
    # ============================================
    # No native DHCP provider exists, so we use PowerShell

    # resource "null_resource" "dhcp_scope" {
    #   provisioner "local-exec" {
    #     command = <<-PS
    #       Invoke-Command -ComputerName dhcp01 -ScriptBlock {
    #         Add-DhcpServerv4Scope `
    #           -Name "WebServers" `
    #           -StartRange 10.0.1.100 `
    #           -EndRange 10.0.1.200 `
    #           -SubnetMask 255.255.255.0 `
    #           -State Active
    #
    #         Set-DhcpServerv4OptionValue `
    #           -ScopeId 10.0.1.0 `
    #           -DnsDomain "${var.domain_name}" `
    #           -DnsServer 10.0.0.10 `
    #           -Router 10.0.1.1
    #       }
    #     PS
    #     interpreter = ["PowerShell", "-Command"]
    #   }
    # }
  EOT
}

# ========================================================================
# SECTION 4: TERRAFORM vs DSC COMPARISON
# ========================================================================

resource "local_file" "dsc_comparison" {
  filename = "./terraform-lab-output/windows-provider/terraform-vs-dsc.json"
  content = jsonencode({
    title = "Terraform vs PowerShell DSC: When to Use Each"
    comparison = {
      terraform = {
        best_for = [
          "Infrastructure provisioning (VMs, networks, storage)",
          "Active Directory object management (OUs, users, groups)",
          "DNS record management",
          "Cloud resource provisioning",
          "Cross-platform infrastructure (Linux + Windows)"
        ]
        manages   = "Infrastructure resources and their lifecycle"
        state     = "Terraform state file tracks all managed resources"
        execution = "Runs from workstation or CI/CD pipeline"
      }
      dsc = {
        best_for = [
          "OS-level configuration (features, services, registry)",
          "Software installation and configuration",
          "Security policy enforcement (baselines)",
          "File/folder permissions",
          "Windows service management"
        ]
        manages   = "Operating system configuration and compliance"
        state     = "LCM (Local Configuration Manager) on each node"
        execution = "Runs on target nodes (push or pull mode)"
      }
      use_together = {
        description = "Best practice: Use BOTH for different layers"
        terraform_layer = "Provision VMs, networking, AD structure, DNS"
        dsc_layer = "Configure OS, install roles, set security baselines"
        workflow = [
          "1. Terraform creates VM and AD objects",
          "2. Terraform passes VM info to DSC configuration",
          "3. DSC configures the OS on the provisioned VM",
          "4. Both maintain their respective state independently"
        ]
      }
    }
    resource_mapping = {
      ad_ou              = "Replaces: New-ADOrganizationalUnit"
      ad_user            = "Replaces: New-ADUser"
      ad_group           = "Replaces: New-ADGroup"
      ad_computer        = "Replaces: New-ADComputer"
      ad_group_membership = "Replaces: Add-ADGroupMember"
      windns_record      = "Replaces: Add-DnsServerResourceRecord*"
      null_resource      = "Bridges gap with PowerShell Invoke-Command"
    }
  })
}

# ========================================================================
# SECTION 5: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-windows-provider.ps1"
  content  = <<-EOT
    # Windows Provider: Terraform vs PowerShell/DSC
    # ===============================================

    # TERRAFORM (AD PROVIDER)           | POWERSHELL (AD MODULE)
    # ----------------------------------|-------------------------------
    # ad_ou                             | New-ADOrganizationalUnit
    # ad_user                           | New-ADUser
    # ad_group                          | New-ADGroup
    # ad_computer                       | New-ADComputer
    # ad_group_membership               | Add-ADGroupMember
    # windns_record                     | Add-DnsServerResourceRecord*
    # terraform plan (preview)          | -WhatIf parameter
    # terraform state (tracking)        | No equivalent (stateless)

    # PowerShell: Traditional AD management
    # Import-Module ActiveDirectory
    #
    # # Create OU
    # New-ADOrganizationalUnit -Name "Servers" `
    #   -Path "DC=corp,DC=example,DC=com" `
    #   -ProtectedFromAccidentalDeletion $$true
    #
    # # Create service account
    # $$securePass = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
    # New-ADUser -Name "svc-webapp" `
    #   -AccountPassword $$securePass `
    #   -Enabled $$true `
    #   -Path "OU=ServiceAccounts,DC=corp,DC=example,DC=com"
    #
    # # Create group and add members
    # New-ADGroup -Name "SG-WebAdmins" -GroupScope Global
    # Add-ADGroupMember -Identity "SG-WebAdmins" -Members "svc-webapp"

    # PowerShell DSC: OS-level configuration
    # Configuration WebServerConfig {
    #   Node "WEB01" {
    #     WindowsFeature IIS {
    #       Ensure = "Present"
    #       Name   = "Web-Server"
    #     }
    #     File WebContent {
    #       Ensure          = "Present"
    #       DestinationPath = "C:\inetpub\wwwroot\index.html"
    #       Contents        = "<h1>Hello from DSC</h1>"
    #     }
    #   }
    # }

    Write-Host "Windows Infrastructure: Terraform vs PowerShell" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Layer 1 - Infrastructure (USE TERRAFORM):" -ForegroundColor Cyan
    Write-Host "    - VMs, Networks, Storage (cloud or on-prem)"
    Write-Host "    - AD Objects (OUs, Users, Groups, Computers)"
    Write-Host "    - DNS Records"
    Write-Host "    - State-tracked and version-controlled"
    Write-Host ""
    Write-Host "  Layer 2 - OS Configuration (USE DSC/PowerShell):" -ForegroundColor Green
    Write-Host "    - Windows Features/Roles"
    Write-Host "    - Software Installation"
    Write-Host "    - Registry Settings"
    Write-Host "    - Security Baselines"
    Write-Host "    - File/Folder Permissions"
    Write-Host ""
    Write-Host "  Layer 3 - Operations (USE PowerShell):" -ForegroundColor Magenta
    Write-Host "    - Monitoring and alerting"
    Write-Host "    - Log analysis and troubleshooting"
    Write-Host "    - Ad-hoc queries and investigations"
    Write-Host "    - Incident response"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "windows_resources" {
  description = "Generated Windows provider reference files"
  value = {
    providers_guide = local_file.windows_providers.filename
    ad_management   = local_file.ad_management.filename
    dns_dhcp        = local_file.dns_dhcp.filename
    dsc_comparison  = local_file.dsc_comparison.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    ad_provider     = "hashicorp/ad provider manages AD objects (OUs, users, groups, computers)"
    winrm           = "Windows providers use WinRM for remote management (port 5986/HTTPS)"
    dns_provider    = "Third-party windns provider manages Windows DNS records"
    terraform_vs_dsc = "Terraform = infrastructure layer, DSC = OS configuration layer"
    use_together    = "Best practice: Terraform provisions, DSC configures, PowerShell operates"
    null_resource   = "Use null_resource + PowerShell for anything without a native provider"
  }
}
