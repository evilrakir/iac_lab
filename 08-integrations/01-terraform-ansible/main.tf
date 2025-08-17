# Terraform + Ansible Integration
# This exercise shows how to use Terraform with Ansible for configuration management

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
  required_version = ">= 1.0"
}

# Variables for the infrastructure
variable "servers" {
  description = "Server configurations"
  type = map(object({
    ip_address = string
    role       = string
    os         = string
  }))
  default = {
    web1 = {
      ip_address = "10.0.1.10"
      role       = "webserver"
      os         = "ubuntu"
    }
    db1 = {
      ip_address = "10.0.1.20"
      role       = "database"
      os         = "ubuntu"
    }
    app1 = {
      ip_address = "10.0.1.30"
      role       = "application"
      os         = "windows"
    }
  }
}

# Generate Ansible inventory from Terraform state
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory/hosts.ini"
  content  = templatefile("${path.module}/templates/inventory.tpl", {
    servers = var.servers
  })
  
  provisioner "local-exec" {
    command = "echo 'Ansible inventory generated at ${self.filename}'"
  }
}

# Generate Ansible host_vars for each server
resource "local_file" "ansible_host_vars" {
  for_each = var.servers
  
  filename = "${path.module}/inventory/host_vars/${each.key}.yml"
  content  = yamlencode({
    ansible_host = each.value.ip_address
    server_role  = each.value.role
    server_os    = each.value.os
    
    # Custom variables based on role
    webserver_port     = each.value.role == "webserver" ? 80 : null
    database_port      = each.value.role == "database" ? 5432 : null
    enable_monitoring  = true
    backup_enabled     = each.value.role == "database" ? true : false
  })
}

# Generate Ansible playbook dynamically
resource "local_file" "ansible_playbook" {
  filename = "${path.module}/playbooks/site.yml"
  content  = <<-EOF
---
- name: Configure all servers
  hosts: all
  become: yes
  tasks:
    - name: Ensure system is updated
      apt:
        update_cache: yes
        upgrade: dist
      when: server_os == "ubuntu"
    
    - name: Install common packages
      package:
        name:
          - git
          - curl
          - vim
        state: present

- name: Configure webservers
  hosts: webservers
  become: yes
  roles:
    - nginx
    - ssl_certificates
  vars:
    nginx_port: 80
    ssl_enabled: true

- name: Configure databases
  hosts: databases
  become: yes
  roles:
    - postgresql
    - backup
  vars:
    postgres_version: 14
    backup_schedule: "0 2 * * *"

- name: Configure application servers
  hosts: applications
  become: yes
  tasks:
    - name: Deploy application
      debug:
        msg: "Deploying application to {{ inventory_hostname }}"
EOF
}

# Run Ansible after Terraform provisions infrastructure
resource "null_resource" "run_ansible" {
  depends_on = [
    local_file.ansible_inventory,
    local_file.ansible_host_vars,
    local_file.ansible_playbook
  ]
  
  # Re-run if inventory changes
  triggers = {
    inventory = local_file.ansible_inventory.content
  }
  
  # Check if Ansible is available
  provisioner "local-exec" {
    command = <<-EOT
      if command -v ansible >/dev/null 2>&1; then
        echo "Ansible is installed, running playbook..."
        ansible-playbook -i ${local_file.ansible_inventory.filename} ${local_file.ansible_playbook.filename} --check
      elif command -v wsl >/dev/null 2>&1; then
        echo "Running Ansible via WSL..."
        wsl ansible-playbook -i ${local_file.ansible_inventory.filename} ${local_file.ansible_playbook.filename} --check
      else
        echo "WARNING: Ansible not found. Install Ansible or WSL to run playbooks."
        echo "Inventory and playbooks have been generated for manual execution."
      fi
    EOT
    
    interpreter = ["PowerShell", "-Command"]
  }
}

# Example: Using Ansible provisioner with remote hosts
resource "null_resource" "configure_remote" {
  count = var.use_remote_provisioning ? 1 : 0
  
  connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host     = "remote-server.example.com"
  }
  
  # Copy Ansible playbook to remote
  provisioner "file" {
    source      = "${path.module}/playbooks/"
    destination = "/tmp/ansible-playbooks"
  }
  
  # Install Ansible on remote if needed
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y ansible"
    ]
  }
  
  # Run Ansible locally on the remote host
  provisioner "remote-exec" {
    inline = [
      "cd /tmp/ansible-playbooks",
      "ansible-playbook -i localhost, -c local site.yml"
    ]
  }
}

# PowerShell + Ansible integration for Windows
resource "local_file" "powershell_ansible_wrapper" {
  filename = "${path.module}/scripts/Run-AnsiblePlaybook.ps1"
  content  = <<-EOF
#Requires -Version 5.1
<#
.SYNOPSIS
    PowerShell wrapper for Ansible execution
.DESCRIPTION
    Runs Ansible playbooks using WSL or Docker
#>
param(
    [string]$PlaybookPath = "${path.module}/playbooks/site.yml",
    [string]$InventoryPath = "${path.module}/inventory/hosts.ini",
    [switch]$UseDocker,
    [switch]$CheckMode
)

function Test-WSL {
    return (Get-Command wsl -ErrorAction SilentlyContinue) -ne $null
}

function Test-Docker {
    return (docker version 2>$null) -ne $null
}

if ($UseDocker -and (Test-Docker)) {
    Write-Host "Running Ansible via Docker..." -ForegroundColor Green
    $cmd = "docker run --rm -v ${PWD}:/ansible -w /ansible cytopia/ansible:latest "
    $cmd += "ansible-playbook -i $InventoryPath $PlaybookPath"
    if ($CheckMode) { $cmd += " --check" }
    Invoke-Expression $cmd
}
elseif (Test-WSL) {
    Write-Host "Running Ansible via WSL..." -ForegroundColor Green
    $wslPath = wsl wslpath -a $PlaybookPath
    $wslInventory = wsl wslpath -a $InventoryPath
    $cmd = "wsl ansible-playbook -i $wslInventory $wslPath"
    if ($CheckMode) { $cmd += " --check" }
    Invoke-Expression $cmd
}
else {
    Write-Error "Neither Docker nor WSL is available for running Ansible"
    Write-Host "Install Docker Desktop or enable WSL2 to continue"
}
EOF
}

# Outputs
output "ansible_inventory_path" {
  value = local_file.ansible_inventory.filename
  description = "Path to generated Ansible inventory"
}

output "ansible_playbook_path" {
  value = local_file.ansible_playbook.filename
  description = "Path to generated Ansible playbook"
}

output "run_ansible_command" {
  value = "ansible-playbook -i ${local_file.ansible_inventory.filename} ${local_file.ansible_playbook.filename}"
  description = "Command to run Ansible playbook"
}

# Variables
variable "use_remote_provisioning" {
  description = "Whether to use remote provisioning"
  type        = bool
  default     = false
}