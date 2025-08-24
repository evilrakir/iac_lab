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
  filename = "${path.module}/output/state-demo.txt"
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
  
  filename = "${path.module}/output/config-${count.index}.json"
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
  
  filename = "${path.module}/output/services/${each.key}.yaml"
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
  filename = "${path.module}/output/.credentials"
  content  = random_password.secret.result
  
  # Sensitive resources are still in state
  # But their values are marked as sensitive
}

# ========================================================================
# SECTION 4: STATE DEPENDENCIES
# ========================================================================

# Create resources with dependencies to show in state
resource "local_file" "primary" {
  filename = "${path.module}/output/primary.txt"
  content  = "Primary resource created at ${timestamp()}"
}

resource "local_file" "dependent" {
  filename = "${path.module}/output/dependent.txt"
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
  filename = "${path.module}/output/persistent.txt"
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
  filename = "${path.module}/output/existing-file.txt"
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
  filename = "${path.module}/output/STATE_COMMANDS.md"
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
  filename = "${path.module}/output/drift-demo.txt"
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
  filename = "${path.module}/output/data-source-state.txt"
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
  filename = "${path.module}/output/WORKSPACES.md"
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