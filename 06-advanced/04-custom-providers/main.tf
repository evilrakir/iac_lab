# ╔════════════════════════════════════════════════════════════════════╗
# ║  CUSTOM TERRAFORM PROVIDERS                                     ║
# ║  Understand the provider plugin architecture                    ║
# ╚════════════════════════════════════════════════════════════════════╝

# Terraform providers are plugins that let Terraform manage external APIs.
# While you'll typically use existing providers, understanding the
# architecture helps you troubleshoot issues and evaluate providers.
# This exercise explores provider internals using the local provider.

# POWERSHELL COMPARISON:
# =====================
# Like building a custom PowerShell module with cmdlets (Get-*, Set-*,
# Remove-*) that manage external resources. Terraform providers follow
# a similar CRUD pattern but with a standardized plugin framework.
# PS: New-CustomResource, Get-CustomResource, Set-CustomResource, Remove-CustomResource
# TF: resource "custom_resource" "example" { ... } -> Create, Read, Update, Delete

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
# SECTION 1: PROVIDER ARCHITECTURE OVERVIEW
# ========================================================================

resource "local_file" "provider_architecture" {
  filename = "./terraform-lab-output/custom-providers/provider-architecture.md"
  content  = <<-EOT
    # Terraform Provider Architecture

    ## How Providers Work

    ```
    terraform apply
        │
        ▼
    ┌──────────────┐     gRPC      ┌──────────────────┐
    │  Terraform   │ ◄──────────► │  Provider Plugin  │
    │  Core (CLI)  │               │  (Go binary)      │
    └──────────────┘               └──────────────────┘
                                           │
                                           ▼
                                   ┌──────────────────┐
                                   │  External API     │
                                   │  (AWS, Azure,     │
                                   │   custom service)  │
                                   └──────────────────┘
    ```

    ## Provider Plugin Lifecycle
    1. `terraform init` downloads provider binaries
    2. Terraform Core starts the provider as a subprocess
    3. Communication happens via gRPC protocol
    4. Provider implements CRUD operations for each resource type
    5. Provider shuts down when Terraform finishes

    ## Provider Binary Location
    ```
    .terraform/
    └── providers/
        └── registry.terraform.io/
            └── hashicorp/
                └── local/
                    └── 2.4.0/
                        └── windows_amd64/
                            └── terraform-provider-local_v2.4.0.exe
    ```

    ## Provider Development Framework
    - **Terraform Plugin SDK v2**: Original framework (Go)
    - **Terraform Plugin Framework**: Newer, recommended framework (Go)
    - Both produce Go binaries that speak gRPC to Terraform Core

    ## Resource CRUD Operations
    Every Terraform resource maps to these operations:

    | Terraform Action | Provider Function | HTTP Equivalent |
    |-----------------|-------------------|----------------|
    | terraform apply (new) | Create() | POST |
    | terraform refresh | Read() | GET |
    | terraform apply (update) | Update() | PUT/PATCH |
    | terraform destroy | Delete() | DELETE |
    | terraform import | ImportState() | GET |
  EOT
}

# ========================================================================
# SECTION 2: PROVIDER SCHEMA EXAMPLE
# ========================================================================

resource "local_file" "provider_schema" {
  filename = "./terraform-lab-output/custom-providers/example-provider-schema.go"
  content  = <<-EOT
    // Example: Simplified Custom Provider in Go
    // This shows the structure of a Terraform provider plugin.
    // Real providers are more complex but follow this pattern.

    package main

    import (
        "context"
        "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
        "github.com/hashicorp/terraform-plugin-sdk/v2/plugin"
    )

    // Provider definition - like a PowerShell module manifest (.psd1)
    func Provider() *schema.Provider {
        return &schema.Provider{
            // Provider-level configuration (authentication, etc.)
            Schema: map[string]*schema.Schema{
                "api_url": {
                    Type:        schema.TypeString,
                    Required:    true,
                    Description: "Base URL of the API",
                },
                "api_key": {
                    Type:        schema.TypeString,
                    Required:    true,
                    Sensitive:   true,
                    Description: "API authentication key",
                },
            },

            // Resources this provider manages
            ResourcesMap: map[string]*schema.Resource{
                "mycloud_server":  resourceServer(),
                "mycloud_network": resourceNetwork(),
            },

            // Data sources (read-only)
            DataSourcesMap: map[string]*schema.Resource{
                "mycloud_image": dataSourceImage(),
            },
        }
    }

    // Resource definition - like a PowerShell class-based DSC resource
    func resourceServer() *schema.Resource {
        return &schema.Resource{
            // CRUD operations
            CreateContext: resourceServerCreate,
            ReadContext:   resourceServerRead,
            UpdateContext: resourceServerUpdate,
            DeleteContext: resourceServerDelete,

            // Schema (like PowerShell parameter definitions)
            Schema: map[string]*schema.Schema{
                "name": {
                    Type:     schema.TypeString,
                    Required: true,
                },
                "size": {
                    Type:     schema.TypeString,
                    Optional: true,
                    Default:  "small",
                },
                "ip_address": {
                    Type:     schema.TypeString,
                    Computed: true, // Set by the API, not the user
                },
            },

            // Import support
            Importer: &schema.ResourceImporter{
                StateContext: schema.ImportStatePassthroughContext,
            },
        }
    }

    // Create operation - like New-CustomResource in PowerShell
    func resourceServerCreate(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
        // 1. Read input values
        name := d.Get("name").(string)
        size := d.Get("size").(string)

        // 2. Call external API
        // server, err := client.CreateServer(name, size)

        // 3. Set resource ID (required!)
        d.SetId("server-12345")

        // 4. Set computed values
        d.Set("ip_address", "10.0.1.100")

        return nil
    }

    // Read operation - like Get-CustomResource in PowerShell
    func resourceServerRead(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
        // Read current state from API
        // If resource no longer exists: d.SetId("")
        return nil
    }

    // Update operation - like Set-CustomResource in PowerShell
    func resourceServerUpdate(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
        // Check what changed and update
        if d.HasChange("size") {
            // Resize the server
        }
        return nil
    }

    // Delete operation - like Remove-CustomResource in PowerShell
    func resourceServerDelete(ctx context.Context, d *schema.ResourceData, m interface{}) diag.Diagnostics {
        // Delete from API
        d.SetId("")
        return nil
    }

    // Main entry point
    func main() {
        plugin.Serve(&plugin.ServeOpts{
            ProviderFunc: Provider,
        })
    }
  EOT
}

# ========================================================================
# SECTION 3: USING CUSTOM/THIRD-PARTY PROVIDERS
# ========================================================================

resource "local_file" "third_party_guide" {
  filename = "./terraform-lab-output/custom-providers/using-third-party-providers.tf"
  content  = <<-EOT
    # ============================================
    # USING THIRD-PARTY PROVIDERS
    # ============================================

    # Third-party providers are installed the same way as official ones.
    # Just specify the source in required_providers.

    terraform {
      required_providers {
        # Official provider (hashicorp namespace)
        aws = {
          source  = "hashicorp/aws"
          version = "~> 5.0"
        }

        # Community provider (different namespace)
        docker = {
          source  = "kreuzwerker/docker"
          version = "~> 3.0"
        }

        # Custom/internal provider (private registry)
        mycompany = {
          source  = "app.terraform.io/mycompany/mycloud"
          version = "~> 1.0"
        }

        # Local filesystem provider (for development)
        # Place binary in: ~/.terraform.d/plugins/
        experimental = {
          source = "example.com/myorg/experimental"
          version = "0.1.0"
        }
      }
    }

    # Install custom providers from local filesystem:
    # 1. Build the Go binary
    # 2. Place it at:
    #    Windows: %APPDATA%\terraform.d\plugins\example.com\myorg\experimental\0.1.0\windows_amd64\
    #    Linux:   ~/.terraform.d/plugins/example.com/myorg/experimental/0.1.0/linux_amd64/
    # 3. Run: terraform init

    # Provider development workflow:
    # 1. Write provider in Go using Plugin SDK or Plugin Framework
    # 2. Build: go build -o terraform-provider-mycloud
    # 3. Test locally with dev_overrides in ~/.terraformrc
    # 4. Publish to Terraform Registry via GitHub releases
  EOT
}

# ========================================================================
# SECTION 4: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-providers.ps1"
  content  = <<-EOT
    # Custom Providers: Terraform vs PowerShell Module Patterns
    # ==========================================================

    # TERRAFORM PROVIDER              | POWERSHELL MODULE
    # --------------------------------|-------------------------------
    # provider "mycloud" { ... }      | Import-Module MyCloud
    # resource "mycloud_server"       | New-MyCloudServer (Create)
    #                                 | Get-MyCloudServer (Read)
    #                                 | Set-MyCloudServer (Update)
    #                                 | Remove-MyCloudServer (Delete)
    # data "mycloud_image"            | Get-MyCloudImage (Read-only)
    # terraform init (download)       | Install-Module MyCloud
    # .terraform/providers/           | $$env:PSModulePath

    # PowerShell: Custom module with CRUD cmdlets (provider equivalent)
    class MyCloudServer {
        [string]$$Name
        [string]$$Size
        [string]$$IpAddress
        [string]$$Id

        # Create (like provider Create function)
        static [MyCloudServer] New([string]$$name, [string]$$size) {
            $$server = [MyCloudServer]::new()
            $$server.Name = $$name
            $$server.Size = $$size
            # Call API to create server
            $$server.Id = [guid]::NewGuid().ToString()
            $$server.IpAddress = "10.0.1.100"
            return $$server
        }

        # Read (like provider Read function)
        static [MyCloudServer] Get([string]$$id) {
            # Call API to read server state
            return $$null
        }

        # Update (like provider Update function)
        [void] Resize([string]$$newSize) {
            $$this.Size = $$newSize
            # Call API to resize
        }

        # Delete (like provider Delete function)
        [void] Remove() {
            # Call API to delete
            $$this.Id = $$null
        }
    }

    Write-Host "Provider Architecture Comparison:" -ForegroundColor Yellow
    Write-Host "  Terraform: Go binary with gRPC, auto-downloaded"
    Write-Host "  PowerShell: .psm1/.dll module, manually installed"
    Write-Host ""
    Write-Host "  Both follow CRUD patterns for resource management"
    Write-Host "  Terraform adds: state tracking, plan/preview, dependency graph"
    Write-Host "  PowerShell adds: pipeline support, object output, tab completion"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "generated_files" {
  description = "Generated reference files"
  value = {
    architecture = local_file.provider_architecture.filename
    schema       = local_file.provider_schema.filename
    third_party  = local_file.third_party_guide.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    architecture   = "Providers are Go binaries that communicate with Terraform via gRPC"
    crud           = "Each resource implements Create, Read, Update, Delete operations"
    plugin_sdk     = "Use Terraform Plugin Framework (newer) or Plugin SDK v2 to build providers"
    third_party    = "Community providers install the same way - just specify the source"
    local_dev      = "Dev providers go in ~/.terraform.d/plugins/ or use dev_overrides"
    ps_comparison  = "Providers are like PowerShell modules with mandatory CRUD cmdlets"
  }
}
