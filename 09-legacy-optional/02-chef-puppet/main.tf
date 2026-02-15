# ╔════════════════════════════════════════════════════════════════════╗
# ║  CHEF AND PUPPET INTEGRATION (LEGACY)                           ║
# ║  Using Terraform with traditional configuration management      ║
# ╚════════════════════════════════════════════════════════════════════╝

# Many organizations still use Chef or Puppet for configuration
# management. Terraform can provision infrastructure and hand off to
# these tools for OS-level configuration. This exercise covers
# integration patterns and migration strategies.

# POWERSHELL COMPARISON:
# =====================
# Chef/Puppet are like PowerShell DSC but cross-platform:
#   DSC:    Configuration { WindowsFeature IIS { Ensure = "Present" } }
#   Chef:   windows_feature 'IIS' { action :install }
#   Puppet: windowsfeature { 'IIS': ensure => 'present' }
# Terraform provisions the VM, Chef/Puppet configures the OS.

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
  default     = "production"
}

variable "chef_server_url" {
  description = "Chef Server URL"
  type        = string
  default     = "https://chef.example.com/organizations/myorg"
}

variable "puppet_server" {
  description = "Puppet Server hostname"
  type        = string
  default     = "puppet.example.com"
}

# ========================================================================
# SECTION 1: TERRAFORM + CHEF INTEGRATION
# ========================================================================

resource "local_file" "chef_integration" {
  filename = "./terraform-lab-output/chef-puppet/terraform-chef-integration.tf"
  content  = <<-EOT
    # ============================================
    # TERRAFORM + CHEF INTEGRATION
    # ============================================

    # Pattern 1: Chef Provisioner (Legacy - being deprecated)
    # Terraform provisions the VM, then bootstraps Chef client
    resource "aws_instance" "web" {
      ami           = "ami-12345678"
      instance_type = "t3.medium"
      key_name      = "deploy-key"

      # Bootstrap Chef on the instance
      provisioner "chef" {
        server_url      = "${var.chef_server_url}"
        user_name       = "terraform"
        user_key        = file("~/.chef/terraform.pem")
        node_name       = "web-$${count.index}"
        run_list        = ["role[webserver]", "recipe[myapp::default]"]
        environment     = "${var.environment}"

        connection {
          type        = "ssh"
          user        = "ec2-user"
          private_key = file("~/.ssh/deploy-key.pem")
          host        = self.public_ip
        }
      }
    }

    # Pattern 2: User Data + Chef (Preferred)
    # Use cloud-init to install and configure Chef client
    resource "aws_instance" "web_userdata" {
      ami           = "ami-12345678"
      instance_type = "t3.medium"

      user_data = <<-USERDATA
        #!/bin/bash
        # Install Chef client
        curl -L https://omnitruck.chef.io/install.sh | bash -s -- -v 17

        # Configure Chef client
        mkdir -p /etc/chef
        cat > /etc/chef/client.rb <<EOF
        chef_server_url  "${var.chef_server_url}"
        node_name        "$$(hostname)"
        environment      "${var.environment}"
        EOF

        # First Chef run
        chef-client -r "role[webserver]"
      USERDATA
    }

    # Pattern 3: Terraform outputs -> Chef data bags
    # Share infrastructure info with Chef via data bags
    # resource "null_resource" "chef_data_bag" {
    #   provisioner "local-exec" {
    #     command = <<-CMD
    #       knife data bag create infrastructure db_config --json '{
    #         "id": "db_config",
    #         "host": "$${aws_db_instance.main.endpoint}",
    #         "port": 5432,
    #         "database": "myapp"
    #       }'
    #     CMD
    #   }
    # }
  EOT
}

# ========================================================================
# SECTION 2: TERRAFORM + PUPPET INTEGRATION
# ========================================================================

resource "local_file" "puppet_integration" {
  filename = "./terraform-lab-output/chef-puppet/terraform-puppet-integration.tf"
  content  = <<-EOT
    # ============================================
    # TERRAFORM + PUPPET INTEGRATION
    # ============================================

    # Pattern 1: User Data + Puppet Agent
    resource "aws_instance" "web" {
      ami           = "ami-12345678"
      instance_type = "t3.medium"

      user_data = <<-USERDATA
        #!/bin/bash
        # Install Puppet agent
        rpm -Uvh https://yum.puppet.com/puppet7-release-el-8.noarch.rpm
        yum install -y puppet-agent

        # Configure Puppet
        cat > /etc/puppetlabs/puppet/puppet.conf <<EOF
        [main]
        server = ${var.puppet_server}
        environment = ${var.environment}
        certname = $$(hostname -f)

        [agent]
        runinterval = 30m
        EOF

        # Start Puppet agent
        /opt/puppetlabs/bin/puppet agent --test --waitforcert 60
        systemctl enable puppet
        systemctl start puppet
      USERDATA
    }

    # Pattern 2: Puppet Bolt from Terraform
    # Run Puppet tasks via Bolt after provisioning
    # resource "null_resource" "puppet_bolt" {
    #   depends_on = [aws_instance.web]
    #
    #   provisioner "local-exec" {
    #     command = <<-CMD
    #       bolt plan run myapp::deploy \
    #         --targets $${aws_instance.web.public_ip} \
    #         environment=${var.environment} \
    #         app_version=2.1.0
    #     CMD
    #   }
    # }

    # Pattern 3: Terraform provides Puppet ENC data
    # External Node Classifier data from Terraform outputs
    # resource "local_file" "puppet_enc_data" {
    #   filename = "/etc/puppetlabs/enc/terraform_nodes.yaml"
    #   content = yamlencode({
    #     for instance in aws_instance.web :
    #     instance.private_ip => {
    #       classes = ["role::webserver"]
    #       parameters = {
    #         environment  = var.environment
    #         db_endpoint  = aws_db_instance.main.endpoint
    #         redis_host   = aws_elasticache_cluster.main.cache_nodes[0].address
    #       }
    #     }
    #   })
    # }
  EOT
}

# ========================================================================
# SECTION 3: MIGRATION STRATEGIES
# ========================================================================

resource "local_file" "migration_guide" {
  filename = "./terraform-lab-output/chef-puppet/migration-strategies.json"
  content = jsonencode({
    title = "Migrating from Chef/Puppet to Modern IaC"
    current_state = {
      description = "Many organizations use Chef/Puppet for BOTH infrastructure and config"
      problem     = "These tools conflate provisioning (create a VM) with configuration (install software)"
    }
    migration_phases = {
      phase_1 = {
        name = "Separate Concerns"
        actions = [
          "Use Terraform for infrastructure provisioning (VMs, networks, DNS)",
          "Keep Chef/Puppet for OS-level configuration only",
          "Pass Terraform outputs to Chef data bags / Puppet hiera"
        ]
        effort = "Low - additive change, doesn't remove existing tools"
      }
      phase_2 = {
        name = "Containerize Applications"
        actions = [
          "Move applications from VM-based to container-based deployment",
          "Replace Chef recipes / Puppet manifests with Dockerfiles",
          "Use Terraform to provision container infrastructure (ECS, AKS, GKE)"
        ]
        effort = "Medium - requires application changes"
      }
      phase_3 = {
        name = "Replace Remaining CM"
        actions = [
          "Use cloud-init / user-data for base OS configuration",
          "Use Ansible for remaining config (simpler, agentless)",
          "Decommission Chef/Puppet servers",
          "Use immutable infrastructure pattern (bake AMIs/images)"
        ]
        effort = "High - full migration, decommission legacy tools"
      }
    }
    comparison = {
      chef   = { type = "Pull-based", agent = "Yes (chef-client)", language = "Ruby DSL", state = "Chef Server" }
      puppet = { type = "Pull-based", agent = "Yes (puppet-agent)", language = "Puppet DSL", state = "PuppetDB" }
      ansible = { type = "Push-based", agent = "No (SSH/WinRM)", language = "YAML", state = "None" }
      terraform = { type = "Push-based", agent = "No (API calls)", language = "HCL", state = "State file" }
      dsc = { type = "Both", agent = "LCM built-in", language = "PowerShell", state = "LCM" }
    }
    recommendation = "Use Terraform for infrastructure + Ansible for config (or containers to skip config entirely)"
  })
}

# ========================================================================
# SECTION 4: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-chef-puppet.ps1"
  content  = <<-EOT
    # Configuration Management: Tool Comparison
    # ============================================

    # TOOL       | PROVISIONING | CONFIG MGMT | AGENT | LANGUAGE
    # ---------- |-------------|-------------|-------|----------
    # Terraform  | Excellent   | None        | No    | HCL
    # Chef       | Basic       | Excellent   | Yes   | Ruby
    # Puppet     | Basic       | Excellent   | Yes   | Puppet DSL
    # Ansible    | Good        | Good        | No    | YAML
    # DSC        | None        | Excellent   | LCM   | PowerShell

    # Migration timeline for a Windows shop:
    # Today:   PowerShell scripts + maybe DSC
    # Step 1:  Add Terraform for infrastructure provisioning
    # Step 2:  Keep DSC/PowerShell for OS configuration
    # Step 3:  Move apps to containers (Dockerfiles replace DSC)
    # Step 4:  Terraform + Kubernetes = full modern stack

    Write-Host "Configuration Management Evolution:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  2010s: Chef/Puppet managed EVERYTHING" -ForegroundColor Red
    Write-Host "  2015s: Terraform emerged for infrastructure"
    Write-Host "  2020s: Containers replaced most config management" -ForegroundColor Green
    Write-Host "  Today: Terraform + Containers is the modern standard" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  For Windows Admins:" -ForegroundColor Magenta
    Write-Host "    Infrastructure: Terraform (VMs, networks, AD, DNS)"
    Write-Host "    OS Config:      DSC or Ansible (features, services)"
    Write-Host "    Applications:   Containers or App Services"
    Write-Host "    Operations:     PowerShell (always!)"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "integration_resources" {
  description = "Generated integration reference files"
  value = {
    chef_integration   = local_file.chef_integration.filename
    puppet_integration = local_file.puppet_integration.filename
    migration_guide    = local_file.migration_guide.filename
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    separation     = "Terraform provisions infrastructure, Chef/Puppet configures OS"
    user_data      = "Prefer cloud-init/user-data over provisioners for bootstrapping"
    data_sharing   = "Pass Terraform outputs to CM tools via data bags, hiera, or ENC"
    migration      = "Migrate gradually: separate concerns -> containerize -> decommission CM"
    modern_stack   = "Modern pattern: Terraform + containers eliminates need for CM tools"
    windows_path   = "Windows: Terraform (infra) + DSC (OS config) + Containers (apps)"
  }
}
