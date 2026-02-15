# ╔════════════════════════════════════════════════════════════════════╗
# ║  AZURE PROVIDER BASICS                                           ║
# ║  Understanding Azure Resource Manager (azurerm) provider         ║
# ╚════════════════════════════════════════════════════════════════════╝

# Azure is the cloud platform most familiar to Windows administrators.
# The azurerm provider maps directly to Azure PowerShell concepts you
# already know: resource groups, storage accounts, VNets, and VMs.
# This exercise generates reference configurations without needing
# an Azure subscription.

# POWERSHELL COMPARISON:
# =====================
# Azure PowerShell:  New-AzResourceGroup -Name "myapp-rg" -Location "eastus"
# Terraform:         resource "azurerm_resource_group" "main" { name = "myapp-rg" }
# Key difference:    PowerShell is imperative (do this), Terraform is declarative (be this)

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
  description = "Project name for resource naming"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

# ========================================================================
# SECTION 1: PROVIDER CONFIGURATION
# ========================================================================

resource "local_file" "provider_config" {
  filename = "./terraform-lab-output/azure-basics/provider-configuration.tf"
  content  = <<-EOT
    # ============================================
    # AZURE PROVIDER CONFIGURATION
    # ============================================

    # The azurerm provider requires the "features" block (even if empty)
    terraform {
      required_providers {
        azurerm = {
          source  = "hashicorp/azurerm"
          version = "~> 3.0"
        }
      }
    }

    # --- Method 1: Azure CLI Authentication (Recommended for Dev) ---
    # First run: az login
    # Then Terraform uses your CLI session automatically
    provider "azurerm" {
      features {}
      # No credentials needed - uses az login session
    }

    # --- Method 2: Service Principal (Recommended for CI/CD) ---
    # provider "azurerm" {
    #   features {}
    #   subscription_id = "00000000-0000-0000-0000-000000000000"
    #   client_id       = "00000000-0000-0000-0000-000000000000"
    #   client_secret   = var.azure_client_secret  # Never hardcode!
    #   tenant_id       = "00000000-0000-0000-0000-000000000000"
    # }

    # --- Method 3: Environment Variables ---
    # export ARM_SUBSCRIPTION_ID="..."
    # export ARM_CLIENT_ID="..."
    # export ARM_CLIENT_SECRET="..."
    # export ARM_TENANT_ID="..."
    # provider "azurerm" {
    #   features {}
    # }

    # --- Method 4: Managed Identity (Azure VMs/Containers) ---
    # provider "azurerm" {
    #   features {}
    #   use_msi = true
    # }
  EOT
}

# ========================================================================
# SECTION 2: CORE AZURE RESOURCES
# ========================================================================

resource "local_file" "core_resources" {
  filename = "./terraform-lab-output/azure-basics/core-resources.tf"
  content  = <<-EOT
    # ============================================
    # CORE AZURE RESOURCES IN TERRAFORM
    # ============================================

    # --- Resource Group (Container for all Azure resources) ---
    # PS Equivalent: New-AzResourceGroup -Name "myapp-dev-rg" -Location "eastus"
    resource "azurerm_resource_group" "main" {
      name     = "${var.project_name}-${var.environment}-rg"
      location = "${var.location}"

      tags = {
        Environment = "${var.environment}"
        Project     = "${var.project_name}"
        ManagedBy   = "terraform"
      }
    }

    # --- Storage Account ---
    # PS Equivalent: New-AzStorageAccount -ResourceGroupName "myapp-dev-rg" ...
    resource "azurerm_storage_account" "main" {
      name                     = "${var.project_name}$${var.environment}sa"  # Must be globally unique, lowercase
      resource_group_name      = azurerm_resource_group.main.name
      location                 = azurerm_resource_group.main.location
      account_tier             = "Standard"
      account_replication_type = "LRS"  # Locally Redundant Storage

      tags = azurerm_resource_group.main.tags
    }

    # --- Virtual Network ---
    # PS Equivalent: New-AzVirtualNetwork -Name "myapp-vnet" -ResourceGroupName ...
    resource "azurerm_virtual_network" "main" {
      name                = "${var.project_name}-${var.environment}-vnet"
      resource_group_name = azurerm_resource_group.main.name
      location            = azurerm_resource_group.main.location
      address_space       = ["10.0.0.0/16"]

      tags = azurerm_resource_group.main.tags
    }

    # --- Subnet ---
    # PS Equivalent: Add-AzVirtualNetworkSubnetConfig -Name "web" ...
    resource "azurerm_subnet" "web" {
      name                 = "web-subnet"
      resource_group_name  = azurerm_resource_group.main.name
      virtual_network_name = azurerm_virtual_network.main.name
      address_prefixes     = ["10.0.1.0/24"]
    }

    resource "azurerm_subnet" "db" {
      name                 = "db-subnet"
      resource_group_name  = azurerm_resource_group.main.name
      virtual_network_name = azurerm_virtual_network.main.name
      address_prefixes     = ["10.0.2.0/24"]
    }

    # --- Network Security Group ---
    # PS Equivalent: New-AzNetworkSecurityGroup + New-AzNetworkSecurityRuleConfig
    resource "azurerm_network_security_group" "web" {
      name                = "${var.project_name}-${var.environment}-web-nsg"
      resource_group_name = azurerm_resource_group.main.name
      location            = azurerm_resource_group.main.location

      security_rule {
        name                       = "AllowHTTP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }

      security_rule {
        name                       = "AllowHTTPS"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }

      tags = azurerm_resource_group.main.tags
    }
  EOT
}

# ========================================================================
# SECTION 3: AZURE VM DEPLOYMENT
# ========================================================================

resource "local_file" "vm_deployment" {
  filename = "./terraform-lab-output/azure-basics/vm-deployment.tf"
  content  = <<-EOT
    # ============================================
    # AZURE VIRTUAL MACHINE WITH TERRAFORM
    # ============================================
    # PS Equivalent: New-AzVM (but with all config tracked in code)

    resource "azurerm_public_ip" "web" {
      name                = "${var.project_name}-${var.environment}-web-pip"
      resource_group_name = azurerm_resource_group.main.name
      location            = azurerm_resource_group.main.location
      allocation_method   = "Static"
      sku                 = "Standard"
    }

    resource "azurerm_network_interface" "web" {
      name                = "${var.project_name}-${var.environment}-web-nic"
      resource_group_name = azurerm_resource_group.main.name
      location            = azurerm_resource_group.main.location

      ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.web.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.web.id
      }
    }

    # --- Linux VM ---
    resource "azurerm_linux_virtual_machine" "web" {
      name                = "${var.project_name}-${var.environment}-web-vm"
      resource_group_name = azurerm_resource_group.main.name
      location            = azurerm_resource_group.main.location
      size                = "Standard_B2s"  # Burstable, cost-effective
      admin_username      = "azureadmin"

      network_interface_ids = [azurerm_network_interface.web.id]

      admin_ssh_key {
        username   = "azureadmin"
        public_key = file("~/.ssh/id_rsa.pub")
      }

      os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
      }

      source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts"
        version   = "latest"
      }

      tags = azurerm_resource_group.main.tags
    }

    # --- Windows VM ---
    # resource "azurerm_windows_virtual_machine" "iis" {
    #   name                = "${var.project_name}-${var.environment}-iis-vm"
    #   resource_group_name = azurerm_resource_group.main.name
    #   location            = azurerm_resource_group.main.location
    #   size                = "Standard_B2s"
    #   admin_username      = "azureadmin"
    #   admin_password      = var.admin_password  # Use Key Vault in prod!
    #
    #   network_interface_ids = [azurerm_network_interface.web.id]
    #
    #   os_disk {
    #     caching              = "ReadWrite"
    #     storage_account_type = "Standard_LRS"
    #   }
    #
    #   source_image_reference {
    #     publisher = "MicrosoftWindowsServer"
    #     offer     = "WindowsServer"
    #     sku       = "2022-Datacenter"
    #     version   = "latest"
    #   }
    # }
  EOT
}

# ========================================================================
# SECTION 4: AZURE-POWERSHELL MAPPING
# ========================================================================

resource "local_file" "azure_mapping" {
  filename = "./terraform-lab-output/azure-basics/azure-terraform-mapping.json"
  content = jsonencode({
    title = "Azure PowerShell to Terraform Resource Mapping"
    mappings = [
      {
        azure_cmdlet    = "New-AzResourceGroup"
        terraform       = "azurerm_resource_group"
        description     = "Resource group (container for resources)"
      },
      {
        azure_cmdlet    = "New-AzStorageAccount"
        terraform       = "azurerm_storage_account"
        description     = "Storage account for blobs, files, queues, tables"
      },
      {
        azure_cmdlet    = "New-AzVirtualNetwork"
        terraform       = "azurerm_virtual_network"
        description     = "Virtual network"
      },
      {
        azure_cmdlet    = "New-AzVM / New-AzVMConfig"
        terraform       = "azurerm_linux_virtual_machine / azurerm_windows_virtual_machine"
        description     = "Virtual machine"
      },
      {
        azure_cmdlet    = "New-AzNetworkSecurityGroup"
        terraform       = "azurerm_network_security_group"
        description     = "Network security group (firewall rules)"
      },
      {
        azure_cmdlet    = "New-AzSqlServer"
        terraform       = "azurerm_mssql_server"
        description     = "SQL Database server"
      },
      {
        azure_cmdlet    = "New-AzWebApp"
        terraform       = "azurerm_linux_web_app / azurerm_windows_web_app"
        description     = "App Service web application"
      },
      {
        azure_cmdlet    = "New-AzKeyVault"
        terraform       = "azurerm_key_vault"
        description     = "Key Vault for secrets management"
      },
      {
        azure_cmdlet    = "New-AzAksCluster"
        terraform       = "azurerm_kubernetes_cluster"
        description     = "Azure Kubernetes Service cluster"
      }
    ]
    authentication = {
      az_cli   = "az login → provider uses session automatically"
      sp       = "Service Principal with ARM_CLIENT_ID/SECRET env vars"
      msi      = "Managed Identity on Azure VMs (use_msi = true)"
      oidc     = "OpenID Connect for GitHub Actions / GitLab CI"
    }
  })
}

# ========================================================================
# SECTION 5: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-azure.ps1"
  content  = <<-EOT
    # Azure: Terraform vs PowerShell Approaches
    # ============================================

    # TERRAFORM                        | POWERSHELL (Az Module)
    # ---------------------------------|-------------------------------
    # azurerm_resource_group           | New-AzResourceGroup
    # azurerm_storage_account          | New-AzStorageAccount
    # azurerm_virtual_network          | New-AzVirtualNetwork
    # azurerm_linux_virtual_machine    | New-AzVM
    # azurerm_network_security_group   | New-AzNetworkSecurityGroup
    # azurerm_key_vault                | New-AzKeyVault
    # terraform plan (preview)         | -WhatIf parameter
    # terraform destroy                | Remove-Az* cmdlets

    # PowerShell: Deploy Azure resources imperatively
    # $$rg = New-AzResourceGroup -Name "myapp-dev-rg" -Location "eastus"
    #
    # $$vnet = New-AzVirtualNetwork `
    #   -ResourceGroupName $$rg.ResourceGroupName `
    #   -Location $$rg.Location `
    #   -Name "myapp-dev-vnet" `
    #   -AddressPrefix "10.0.0.0/16"
    #
    # $$subnet = Add-AzVirtualNetworkSubnetConfig `
    #   -Name "web-subnet" `
    #   -VirtualNetwork $$vnet `
    #   -AddressPrefix "10.0.1.0/24"
    # $$vnet | Set-AzVirtualNetwork

    # Terraform: Same resources declared in state
    # resource "azurerm_resource_group" "main" {
    #   name     = "myapp-dev-rg"
    #   location = "eastus"
    # }
    # resource "azurerm_virtual_network" "main" {
    #   name                = "myapp-dev-vnet"
    #   resource_group_name = azurerm_resource_group.main.name
    #   location            = azurerm_resource_group.main.location
    #   address_space       = ["10.0.0.0/16"]
    # }

    Write-Host "Azure: Terraform vs PowerShell" -ForegroundColor Yellow
    Write-Host "  PowerShell: Familiar Az module commands (imperative)"
    Write-Host "  Terraform:  Declarative configs tracked in state"
    Write-Host ""
    Write-Host "  Key Differences:" -ForegroundColor Cyan
    Write-Host "  - PS: 'Create this now' vs TF: 'This should exist'"
    Write-Host "  - PS: No built-in state vs TF: Tracks all resources"
    Write-Host "  - PS: -WhatIf for preview vs TF: terraform plan"
    Write-Host "  - PS: Great for ad-hoc tasks vs TF: Great for repeatable infra"
    Write-Host ""
    Write-Host "  Best practice: Use Terraform for infrastructure,"
    Write-Host "  PowerShell for operational tasks and investigation"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "azure_resources" {
  description = "Generated Azure reference files"
  value = {
    provider_config = local_file.provider_config.filename
    core_resources  = local_file.core_resources.filename
    vm_deployment   = local_file.vm_deployment.filename
    resource_mapping = local_file.azure_mapping.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    provider_setup  = "Azure provider requires 'features {}' block - even if empty"
    authentication  = "Use az login for dev, Service Principal or Managed Identity for CI/CD"
    resource_groups = "All Azure resources live in resource groups - create them first"
    naming          = "Azure has naming rules: storage accounts must be lowercase, globally unique"
    familiar        = "Azure concepts map directly: Az module cmdlets → azurerm_* resources"
    state_tracking  = "Terraform tracks resource state - no more 'did I already create this?'"
  }
}
