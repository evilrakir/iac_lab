# Exercise: Understanding Terraform State
# Learn how Terraform tracks your infrastructure

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  required_version = ">= 1.0"
}

# ========================================================================
# SECTION 1: UNDERSTANDING STATE BASICS
# ========================================================================

# Terraform state is like PowerShell's session state
# It remembers what resources exist and their properties

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "state-demo"
}

# This resource will be tracked in state
resource "random_id" "state_id" {
  byte_length = 4
  
  # Keepers demonstrate state updates
  keepers = {
    project = var.project_name
    # Change this to see state updates
    version = "1.0"
  }
}

# Create a file - Terraform tracks this in state
resource "local_file" "state_example" {
  filename = "./terraform-lab-output/state-demo.txt"
  content  = <<-EOT
    Terraform State Demonstration
    =============================
    
    Resource ID: ${random_id.state_id.hex}
    Project: ${var.project_name}
    
    This file is tracked in terraform.tfstate
    
    State contains:
    - Resource type and name
    - Resource properties
    - Resource dependencies
    - Provider information
  EOT
}

# ========================================================================
# SECTION 2: STATE ATTRIBUTES
# ========================================================================

# Create resources that demonstrate state attributes
resource "local_file" "config_files" {
  count = 3
  
  filename = "./terraform-lab-output/config-${count.index}.json"
  content = jsonencode({
    index       = count.index
    id          = "config-${count.index}"
    created_at  = timestamp()
    state_info  = "This is resource local_file.config_files[${count.index}] in state"
  })
}

# State tracks for_each resources differently
resource "local_file" "service_configs" {
  for_each = {
    web = { port = 8080, enabled = true }
    api = { port = 3000, enabled = true }
    db  = { port = 5432, enabled = false }
  }
  
  filename = "./terraform-lab-output/services/${each.key}.yaml"
  content = yamlencode({
    service = each.key
    config  = each.value
    state_path = "local_file.service_configs[\"${each.key}\"]"
  })
}

# ========================================================================
# SECTION 3: STATE METADATA
# ========================================================================

# Resources to demonstrate state metadata
resource "random_password" "secret" {
  length  = 16
  special = true
  
  # This will be marked sensitive in state
  # State file shows: "result": "(sensitive value)"
}

resource "local_sensitive_file" "credentials" {
  filename = "./terraform-lab-output/.credentials"
  content  = random_password.secret.result
  
  # Sensitive resources are still in state
  # But their values are marked as sensitive
}

# ========================================================================
# SECTION 4: STATE DEPENDENCIES
# ========================================================================

# Create resources with dependencies to show in state
resource "local_file" "primary" {
  filename = "./terraform-lab-output/primary.txt"
  content  = "Primary resource created at ${timestamp()}"
}

resource "local_file" "dependent" {
  filename = "./terraform-lab-output/dependent.txt"
  content  = <<-EOT
    This resource depends on: ${local_file.primary.filename}
    Primary ID: ${local_file.primary.id}
    
    State tracks this dependency relationship
  EOT
  
  # Explicit dependency
  depends_on = [local_file.primary]
}

# ========================================================================
# SECTION 5: STATE LIFECYCLE
# ========================================================================

# Resource with lifecycle rules
resource "local_file" "persistent" {
  filename = "./terraform-lab-output/persistent.txt"
  content  = "This file demonstrates lifecycle rules"
  
  lifecycle {
    # These rules affect how state is managed
    create_before_destroy = true
    ignore_changes = [content]  # State ignores content changes
  }
}

# ========================================================================
# SECTION 6: IMPORT EXISTING RESOURCES
# ========================================================================

# Create a file outside of Terraform (simulating existing infrastructure)
resource "local_file" "manual_creation" {
  filename = "./terraform-lab-output/existing-file.txt"
  content  = <<-EOT
    This file simulates existing infrastructure.
    
    To import existing resources into state:
    1. Define the resource in configuration
    2. Run: terraform import resource_type.name resource_id
    
    Example:
    terraform import local_file.existing existing-file.txt
  EOT
}

# ========================================================================
# SECTION 7: STATE INSPECTION
# ========================================================================

# Create a comprehensive state demonstration
resource "local_file" "state_inspection_guide" {
  filename = "./terraform-lab-output/STATE_COMMANDS.md"
  content  = <<-EOT
    # Terraform State Commands
    
    ## Inspecting State
    
    ### List all resources in state:
    ```bash
    terraform state list
    ```
    
    ### Show specific resource:
    ```bash
    terraform state show local_file.state_example
    terraform state show 'local_file.config_files[0]'
    terraform state show 'local_file.service_configs["web"]'
    ```
    
    ### Show entire state:
    ```bash
    terraform show
    ```
    
    ### Show state in JSON:
    ```bash
    terraform show -json
    ```
    
    ## Modifying State
    
    ### Remove resource from state (without destroying):
    ```bash
    terraform state rm local_file.manual_creation
    ```
    
    ### Move resource in state:
    ```bash
    terraform state mv local_file.old local_file.new
    ```
    
    ### Pull current state:
    ```bash
    terraform state pull > backup.tfstate
    ```
    
    ### Push state (dangerous!):
    ```bash
    terraform state push backup.tfstate
    ```
    
    ## State File Structure
    
    The terraform.tfstate file contains:
    - version: Terraform state format version
    - terraform_version: Version of Terraform that created it
    - serial: Increments with each state change
    - lineage: Unique ID for this state history
    - resources: Array of all managed resources
    
    ## PowerShell Comparison
    
    Terraform state is like:
    - PowerShell session variables
    - Azure Resource Manager state
    - Configuration management databases
    
    ## Important Notes
    
    1. **Never edit state files manually**
    2. **Always backup state before operations**
    3. **Use state locking in team environments**
    4. **Consider remote state for production**
    5. **State contains sensitive information**
    
    ## State Location
    
    Current state file: ${path.module}/terraform.tfstate
    Backup state file: ${path.module}/terraform.tfstate.backup
    
    Generated at: ${timestamp()}
  EOT
}

# ========================================================================
# SECTION 8: STATE VS CONFIGURATION
# ========================================================================

# Demonstrate drift between state and configuration
resource "local_file" "drift_demo" {
  filename = "./terraform-lab-output/drift-demo.txt"
  content  = <<-EOT
    State vs Configuration
    ======================
    
    Configuration (this file): Desired state
    State file: Current/actual state
    
    Drift occurs when:
    1. Resources are changed outside Terraform
    2. State file is corrupted or lost
    3. Manual state modifications
    
    To detect drift:
    - terraform plan (shows differences)
    - terraform refresh (updates state from real infrastructure)
    
    Resource ID in state: Will be generated
    Timestamp: ${timestamp()}
  EOT
}

# ========================================================================
# SECTION 9: DATA SOURCES AND STATE
# ========================================================================

# Data sources don't create resources but read them
data "local_file" "read_existing" {
  filename = local_file.state_example.filename
  
  depends_on = [local_file.state_example]
}

# Create a file showing data source information
resource "local_file" "data_source_info" {
  filename = "./terraform-lab-output/data-source-state.txt"
  content  = <<-EOT
    Data Sources in State
    =====================
    
    Data sources are read-only and tracked differently in state.
    
    Resource path in state: local_file.state_example
    Data source path in state: data.local_file.read_existing
    
    File content length: ${length(data.local_file.read_existing.content)}
    File ID from data source: ${data.local_file.read_existing.id}
    
    Data sources:
    - Are refreshed on every run
    - Don't modify infrastructure
    - Are prefixed with "data." in state
  EOT
}

# ========================================================================
# SECTION 10: STATE WORKSPACES PREPARATION
# ========================================================================

resource "local_file" "workspace_info" {
  filename = "./terraform-lab-output/WORKSPACES.md"
  content  = <<-EOT
    # Terraform Workspaces
    
    Workspaces allow multiple states for the same configuration.
    
    ## Workspace Commands
    
    ### List workspaces:
    ```bash
    terraform workspace list
    ```
    
    ### Create new workspace:
    ```bash
    terraform workspace new development
    terraform workspace new staging
    terraform workspace new production
    ```
    
    ### Switch workspace:
    ```bash
    terraform workspace select development
    ```
    
    ### Show current workspace:
    ```bash
    terraform workspace show
    ```
    
    ## How Workspaces Work
    
    - Each workspace has its own state file
    - Default workspace: terraform.tfstate
    - Other workspaces: terraform.tfstate.d/[workspace]/terraform.tfstate
    
    ## Use Cases
    
    1. Multiple environments (dev/staging/prod)
    2. Feature branch deployments
    3. Testing infrastructure changes
    4. Isolated development environments
    
    ## Current Workspace
    
    You are in the 'default' workspace.
    
    ## PowerShell Analogy
    
    Workspaces are like PowerShell runspaces:
    - Isolated execution environments
    - Separate variable scopes
    - Independent state
    
    Generated at: ${timestamp()}
  EOT
}

# ========================================================================
# POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-state.ps1"
  
  content = <<-EOT
    # PowerShell Equivalent of Terraform State Management
    # ====================================================
    # This shows how Terraform state compares to PowerShell session management
    
    Write-Host "=== Terraform State vs PowerShell Session State ===" -ForegroundColor Green
    
    # TERRAFORM STATE:
    # Terraform automatically tracks all resources in terraform.tfstate
    # terraform {
    #   backend "local" {
    #     path = "terraform.tfstate"
    #   }
    # }
    
    # POWERSHELL EQUIVALENT:
    # Manual state tracking with variables or files
    $script:InfrastructureState = @{
        Resources = @{}
        LastModified = Get-Date
        Version = "1.0"
    }
    
    Write-Host "`nManual State Management in PowerShell:" -ForegroundColor Yellow
    
    # Creating a resource and tracking it
    function New-InfrastructureResource {
        param(
            [string]$Name,
            [string]$Type,
            [hashtable]$Properties
        )
        
        # Create the resource (e.g., a file)
        $resourcePath = "./terraform-lab-output/$Name.json"
        $Properties | ConvertTo-Json | Set-Content -Path $resourcePath
        
        # Track in our state
        $script:InfrastructureState.Resources[$Name] = @{
            Type = $Type
            Path = $resourcePath
            Properties = $Properties
            CreatedAt = Get-Date
            Id = [guid]::NewGuid().ToString()
        }
        
        Write-Host "  Created and tracked: $Name"
        return $script:InfrastructureState.Resources[$Name]
    }
    
    # Example resource creation
    $webConfig = New-InfrastructureResource -Name "web-config" -Type "config" -Properties @{
        port = 8080
        environment = "dev"
    }
    
    # Saving state to file (like terraform.tfstate)
    Write-Host "`nSaving State to File:" -ForegroundColor Yellow
    $script:InfrastructureState | ConvertTo-Json -Depth 10 | 
        Set-Content -Path "./terraform-lab-output/infrastructure-state.json"
    Write-Host "  State saved to infrastructure-state.json"
    
    # Loading state from file
    Write-Host "`nLoading State from File:" -ForegroundColor Yellow
    if (Test-Path "./terraform-lab-output/infrastructure-state.json") {
        $loadedState = Get-Content "./terraform-lab-output/infrastructure-state.json" | 
            ConvertFrom-Json
        Write-Host "  State loaded with $($loadedState.Resources.Count) resources"
    }
    
    # State operations comparison
    Write-Host "`nState Operations Comparison:" -ForegroundColor Yellow
    Write-Host @"
    Terraform: terraform state list
    PowerShell: `$script:InfrastructureState.Resources.Keys
    
    Terraform: terraform state show resource.name
    PowerShell: `$script:InfrastructureState.Resources['name']
    
    Terraform: terraform state rm resource.name
    PowerShell: `$script:InfrastructureState.Resources.Remove('name')
    
    Terraform: terraform refresh
    PowerShell: Custom function to check actual vs tracked state
    "@
    
    # Drift detection example
    Write-Host "`nDrift Detection (Manual in PowerShell):" -ForegroundColor Yellow
    function Test-InfrastructureDrift {
        foreach ($resource in $script:InfrastructureState.Resources.GetEnumerator()) {
            if (Test-Path $resource.Value.Path) {
                $actual = Get-Content $resource.Value.Path | ConvertFrom-Json
                $tracked = $resource.Value.Properties
                
                # Simple comparison
                $actualJson = $actual | ConvertTo-Json -Compress
                $trackedJson = $tracked | ConvertTo-Json -Compress
                
                if ($actualJson -ne $trackedJson) {
                    Write-Host "  DRIFT DETECTED: $($resource.Key)" -ForegroundColor Red
                } else {
                    Write-Host "  No drift: $($resource.Key)" -ForegroundColor Green
                }
            } else {
                Write-Host "  MISSING: $($resource.Key)" -ForegroundColor Red
            }
        }
    }
    
    # State locking comparison
    Write-Host "`nState Locking:" -ForegroundColor Yellow
    Write-Host @"
    TERRAFORM:
    - Automatic state locking with most backends
    - Prevents concurrent modifications
    - terraform force-unlock for stuck locks
    
    POWERSHELL:
    - Must implement manual locking:
    "@
    
    # Manual locking example
    function Lock-InfrastructureState {
        $lockFile = "./terraform-lab-output/.state.lock"
        $lockInfo = @{
            User = $env:USERNAME
            Process = $PID
            Time = Get-Date
        }
        
        if (Test-Path $lockFile) {
            Write-Host "  State is locked!" -ForegroundColor Red
            return $false
        }
        
        $lockInfo | ConvertTo-Json | Set-Content -Path $lockFile
        Write-Host "  State locked successfully"
        return $true
    }
    
    function Unlock-InfrastructureState {
        $lockFile = "./terraform-lab-output/.state.lock"
        if (Test-Path $lockFile) {
            Remove-Item $lockFile
            Write-Host "  State unlocked"
        }
    }
    
    # KEY DIFFERENCES:
    Write-Host "`n=== Key Differences ===" -ForegroundColor Magenta
    Write-Host @"
    1. AUTOMATIC vs MANUAL:
       - Terraform: Automatic state tracking
       - PowerShell: Manual state management required
    
    2. STATE FORMAT:
       - Terraform: Structured JSON with metadata
       - PowerShell: Custom format (usually JSON/XML)
    
    3. DRIFT DETECTION:
       - Terraform: Built-in with refresh
       - PowerShell: Must implement comparison logic
    
    4. STATE LOCKING:
       - Terraform: Automatic with backends
       - PowerShell: Manual file/mutex locking
    
    5. REMOTE STATE:
       - Terraform: Built-in backend support (S3, Azure, etc.)
       - PowerShell: Custom implementation needed
    
    6. STATE OPERATIONS:
       - Terraform: Rich CLI commands for state
       - PowerShell: Custom functions required
    
    7. ROLLBACK:
       - Terraform: State file versions/backups
       - PowerShell: Manual backup strategy needed
    "@
    
    Write-Host "`nTerraform's state management is a key differentiator from imperative tools!" -ForegroundColor Green
  EOT
  
  depends_on = [
    local_file.state_demo_file,
    local_file.state_commands
  ]
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "state_file_location" {
  description = "Location of the Terraform state file"
  value       = "${path.module}/terraform.tfstate"
}

output "resources_in_state" {
  description = "Resources that will be tracked in state"
  value = {
    single_resources = [
      "random_id.state_id",
      "local_file.state_example",
      "random_password.secret",
      "local_sensitive_file.credentials",
      "local_file.primary",
      "local_file.dependent",
      "local_file.persistent",
      "local_file.manual_creation",
      "local_file.state_inspection_guide",
      "local_file.drift_demo",
      "local_file.data_source_info",
      "local_file.workspace_info"
    ]
    
    count_resources = [
      for i in range(3) : "local_file.config_files[${i}]"
    ]
    
    for_each_resources = [
      for key in keys(local_file.service_configs) : 
      "local_file.service_configs[\"${key}\"]"
    ]
    
    data_sources = [
      "data.local_file.read_existing"
    ]
  }
}

output "state_commands_reference" {
  description = "Quick reference for state commands"
  value = {
    inspect = {
      list = "terraform state list"
      show = "terraform state show [resource]"
      pull = "terraform state pull"
    }
    
    modify = {
      remove = "terraform state rm [resource]"
      move   = "terraform state mv [old] [new]"
      import = "terraform import [resource] [id]"
    }
    
    workspace = {
      list   = "terraform workspace list"
      new    = "terraform workspace new [name]"
      select = "terraform workspace select [name]"
      show   = "terraform workspace show"
    }
  }
}

output "learning_summary" {
  description = "What you learned about Terraform state"
  value = <<-EOT
    
    TERRAFORM STATE CONCEPTS:
    
    1. State Basics:
       - Tracks infrastructure resources
       - Maps configuration to real resources
       - Stores resource attributes and metadata
    
    2. State Contents:
       - Resource identifiers
       - Resource attributes
       - Dependencies between resources
       - Provider configurations
    
    3. State Management:
       - Inspection commands (list, show)
       - Modification commands (rm, mv, import)
       - State locking for concurrent access
    
    4. State Storage:
       - Local state (terraform.tfstate)
       - Remote state (S3, Azure Storage, etc.)
       - State backups (.backup files)
    
    5. Best Practices:
       - Never edit state manually
       - Use remote state for teams
       - Enable state locking
       - Regular state backups
       - Sensitive data in state
    
    Files created: 12+ resources
    State file: ${path.module}/terraform.tfstate
    
  EOT
}