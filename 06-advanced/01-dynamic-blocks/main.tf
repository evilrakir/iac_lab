# ╔════════════════════════════════════════════════════════════════════╗
# ║  DYNAMIC BLOCKS                                                  ║
# ║  Generate repeated nested blocks from data structures           ║
# ╚════════════════════════════════════════════════════════════════════╝

# Dynamic blocks let you programmatically generate repeated nested blocks
# inside resources. Instead of copy-pasting similar blocks, you define
# them once and iterate over a collection. This exercise demonstrates
# dynamic blocks using the local provider to generate configurations.

# POWERSHELL COMPARISON:
# =====================
# Like using ForEach-Object to build configuration sections:
#   $rules | ForEach-Object { Add-FirewallRule -Name $_.Name -Port $_.Port }
# In Terraform: dynamic "ingress" { for_each = var.rules; content { ... } }

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

variable "firewall_rules" {
  description = "List of firewall rules to generate"
  type = list(object({
    name        = string
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      name        = "HTTP"
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP traffic"
    },
    {
      name        = "HTTPS"
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTPS traffic"
    },
    {
      name        = "SSH"
      port        = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "Allow SSH from internal networks"
    },
    {
      name        = "RDP"
      port        = 3389
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "Allow RDP from internal networks"
    },
    {
      name        = "WinRM"
      port        = 5985
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]
      description = "Allow WinRM from internal networks"
    }
  ]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "development"
    ManagedBy   = "terraform"
    Team        = "infrastructure"
    CostCenter  = "IT-001"
  }
}

variable "notification_channels" {
  description = "Alert notification channels"
  type = list(object({
    type    = string
    target  = string
    events  = list(string)
  }))
  default = [
    {
      type   = "email"
      target = "ops-team@example.com"
      events = ["critical", "warning"]
    },
    {
      type   = "slack"
      target = "#infra-alerts"
      events = ["critical"]
    },
    {
      type   = "pagerduty"
      target = "PXXXXXX"
      events = ["critical"]
    }
  ]
}

# ========================================================================
# SECTION 1: BASIC DYNAMIC BLOCKS
# ========================================================================

# Generate a security group config using dynamic blocks
resource "local_file" "security_group" {
  filename = "./terraform-lab-output/dynamic-blocks/security-group.tf"
  content  = <<-EOT
    # Security group generated with dynamic blocks
    # Instead of writing 5 separate ingress blocks, we generate them!

    resource "aws_security_group" "web" {
      name        = "web-server-sg"
      description = "Web server security group"
      vpc_id      = var.vpc_id

      %{for rule in var.firewall_rules}
      # ${rule.name}: ${rule.description}
      ingress {
        description = "${rule.description}"
        from_port   = ${rule.port}
        to_port     = ${rule.port}
        protocol    = "${rule.protocol}"
        cidr_blocks = ${jsonencode(rule.cidr_blocks)}
      }

      %{endfor}

      egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    }

    # The dynamic block equivalent (what you'd actually write):
    #
    # resource "aws_security_group" "web" {
    #   name   = "web-server-sg"
    #   vpc_id = var.vpc_id
    #
    #   dynamic "ingress" {
    #     for_each = var.firewall_rules
    #     content {
    #       description = ingress.value.description
    #       from_port   = ingress.value.port
    #       to_port     = ingress.value.port
    #       protocol    = ingress.value.protocol
    #       cidr_blocks = ingress.value.cidr_blocks
    #     }
    #   }
    # }
  EOT
}

# ========================================================================
# SECTION 2: DYNAMIC BLOCKS REFERENCE
# ========================================================================

resource "local_file" "dynamic_reference" {
  filename = "./terraform-lab-output/dynamic-blocks/dynamic-block-reference.tf"
  content  = <<-EOT
    # ============================================
    # DYNAMIC BLOCK SYNTAX REFERENCE
    # ============================================

    # Basic syntax:
    # dynamic "BLOCK_NAME" {
    #   for_each = COLLECTION
    #   content {
    #     # Use BLOCK_NAME.key and BLOCK_NAME.value
    #     attribute = BLOCK_NAME.value.field
    #   }
    # }

    # --- Example 1: Security Group Ingress Rules ---
    variable "rules" {
      type = list(object({
        port        = number
        cidr_blocks = list(string)
      }))
    }

    resource "aws_security_group" "example" {
      name = "dynamic-example"

      dynamic "ingress" {
        for_each = var.rules
        content {
          from_port   = ingress.value.port
          to_port     = ingress.value.port
          protocol    = "tcp"
          cidr_blocks = ingress.value.cidr_blocks
        }
      }
    }

    # --- Example 2: Tags using dynamic blocks ---
    resource "aws_autoscaling_group" "example" {
      # ...

      dynamic "tag" {
        for_each = var.tags
        content {
          key                 = tag.key
          value               = tag.value
          propagate_at_launch = true
        }
      }
    }

    # --- Example 3: Conditional dynamic blocks ---
    variable "enable_logging" {
      type    = bool
      default = true
    }

    resource "aws_lb" "example" {
      name = "my-lb"

      # Only create access_logs block if logging is enabled
      dynamic "access_logs" {
        for_each = var.enable_logging ? [1] : []
        content {
          bucket  = aws_s3_bucket.logs.id
          prefix  = "lb-logs"
          enabled = true
        }
      }
    }

    # --- Example 4: Nested dynamic blocks ---
    resource "aws_lb_listener" "example" {
      load_balancer_arn = aws_lb.example.arn
      port              = 443

      dynamic "default_action" {
        for_each = var.listener_rules
        content {
          type             = default_action.value.type
          target_group_arn = default_action.value.target_group

          dynamic "redirect" {
            for_each = default_action.value.type == "redirect" ? [1] : []
            content {
              port        = "443"
              protocol    = "HTTPS"
              status_code = "HTTP_301"
            }
          }
        }
      }
    }

    # --- When NOT to use dynamic blocks ---
    # 1. When you only have 1-2 blocks (just write them statically)
    # 2. When it makes the config harder to read
    # 3. When you need complex conditional logic inside
    # Rule of thumb: Use dynamic blocks for 3+ similar blocks
  EOT
}

# ========================================================================
# SECTION 3: GENERATED CONFIGURATIONS SHOWING THE PATTERN
# ========================================================================

resource "local_file" "notification_config" {
  filename = "./terraform-lab-output/dynamic-blocks/notification-config.json"
  content = jsonencode({
    title = "Alert Configuration Generated from Dynamic Data"
    notifications = {
      for channel in var.notification_channels : channel.type => {
        target = channel.target
        events = channel.events
        config = "dynamic block would generate a notification_channel block for each"
      }
    }
    tag_blocks = {
      for key, value in var.tags : key => {
        key                 = key
        value               = value
        propagate_at_launch = true
        generated_by        = "dynamic tag block with for_each = var.tags"
      }
    }
  })
}

# ========================================================================
# SECTION 4: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-dynamic-blocks.ps1"
  content  = <<-EOT
    # Dynamic Blocks: Terraform vs PowerShell Patterns
    # ==================================================

    # TERRAFORM DYNAMIC BLOCKS        | POWERSHELL EQUIVALENT
    # --------------------------------|-------------------------------
    # dynamic "ingress" { ... }       | ForEach-Object pipeline
    # for_each = var.rules            | $rules | ForEach-Object { }
    # ingress.value.port              | $_.Port
    # Conditional: for_each = cond?[1]:[] | if ($condition) { }

    # PowerShell: Building firewall rules dynamically
    $$firewallRules = @(
        @{ Name = "HTTP";  Port = 80;   CIDR = "0.0.0.0/0" }
        @{ Name = "HTTPS"; Port = 443;  CIDR = "0.0.0.0/0" }
        @{ Name = "SSH";   Port = 22;   CIDR = "10.0.0.0/8" }
        @{ Name = "RDP";   Port = 3389; CIDR = "10.0.0.0/8" }
    )

    # Dynamic generation (like Terraform dynamic blocks)
    $$firewallRules | ForEach-Object {
        Write-Host "Adding rule: $$($_.Name) - Port $$($_.Port) from $$($_.CIDR)"
        # New-NetFirewallRule -DisplayName $_.Name -Direction Inbound `
        #   -LocalPort $_.Port -Protocol TCP -Action Allow
    }

    # Building dynamic tags (like dynamic "tag" block)
    $$tags = @{
        Environment = "production"
        ManagedBy   = "terraform"
        Team        = "infrastructure"
    }

    $$tagObjects = $$tags.GetEnumerator() | ForEach-Object {
        @{
            Key                 = $$_.Key
            Value               = $$_.Value
            PropagateAtLaunch  = $$true
        }
    }

    Write-Host "`nKey Insight:" -ForegroundColor Yellow
    Write-Host "  Terraform dynamic blocks are the HCL equivalent of"
    Write-Host "  PowerShell's ForEach-Object pipeline for generating"
    Write-Host "  repeated configuration blocks from data."
    Write-Host "  Both turn data into configuration dynamically."
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "generated_rules" {
  description = "Firewall rules that would be generated by dynamic blocks"
  value = {
    for rule in var.firewall_rules : rule.name => {
      port        = rule.port
      protocol    = rule.protocol
      cidr_blocks = rule.cidr_blocks
    }
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    syntax         = "dynamic \"block_name\" { for_each = collection; content { ... } }"
    iterator       = "Access values via block_name.key and block_name.value"
    conditional    = "Use for_each = condition ? [1] : [] for optional blocks"
    nested         = "Dynamic blocks can be nested for complex structures"
    when_to_use    = "Best for 3+ similar nested blocks generated from data"
    avoid_overuse  = "Don't use when static blocks are clearer"
  }
}
