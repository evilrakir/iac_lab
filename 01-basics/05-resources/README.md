# Exercise 5: Terraform Resources

## Learning Objectives
- Understand resource lifecycle and dependencies
- Learn different resource creation patterns (count, for_each, conditional)
- Practice resource dependencies (explicit and implicit)
- Explore advanced resource features (lifecycle rules, provisioners)
- See how resources work together to build infrastructure

## What Are Resources?
Resources are the most important element in Terraform. They describe infrastructure objects like files, servers, databases, networks, etc. Resources have a lifecycle: create, update, destroy.

## PowerShell Analogy
```powershell
# PowerShell creating infrastructure-like objects
$servers = @()
for ($i = 1; $i -le 3; $i++) {
    $server = New-Object PSObject -Property @{
        Name = "Server-$i"
        Role = "WebServer"
        Created = Get-Date
    }
    $servers += $server
}

# Similar to Terraform resources with count
resource "local_file" "servers" {
  count = 3
  filename = "server-${count.index + 1}.conf"
  content = "Server configuration..."
}
```

## Key Concepts Demonstrated

### 1. Resource Creation Patterns

#### Basic Resource
```hcl
resource "local_file" "simple" {
  filename = "example.txt"
  content  = "Hello World"
}
```

#### Count Pattern (Multiple similar resources)
```hcl
resource "local_file" "servers" {
  count = 3
  filename = "server-${count.index + 1}.conf"
  content = "Server ${count.index + 1} config"
}
```

#### For_each Pattern (Resources from map/set)
```hcl
resource "local_file" "services" {
  for_each = var.service_config
  filename = "${each.key}.yaml"
  content = "Service: ${each.key}"
}
```

#### Conditional Resources
```hcl
resource "local_file" "backup" {
  count = var.enable_backup ? 1 : 0
  filename = "backup.conf"
  content = "Backup configuration"
}
```

### 2. Resource Dependencies

#### Implicit Dependencies (automatic)
```hcl
resource "local_file" "config" {
  filename = "app.conf"
  content = "config data"
}

resource "local_file" "app" {
  filename = "app.txt"
  content = "Config file: ${local_file.config.filename}"  # References config
  # Terraform automatically knows to create config first
}
```

#### Explicit Dependencies
```hcl
resource "local_file" "database" {
  filename = "db.conf"
  content = "database config"
  
  depends_on = [local_file.network]  # Explicit dependency
}
```

### 3. Lifecycle Management
```hcl
resource "local_file" "important" {
  filename = "important.conf"
  content = "important data"
  
  lifecycle {
    prevent_destroy = true           # Cannot be destroyed
    create_before_destroy = true     # Create new before destroying old
    ignore_changes = [content]       # Ignore changes to content
  }
}
```

### 4. Provisioners (Running Commands)
```hcl
resource "null_resource" "setup" {
  provisioner "local-exec" {
    command = "echo 'Infrastructure setup complete'"
  }
}
```

## Commands to Run

```bash
# Initialize the exercise
terraform init

# See the plan (notice dependency order)
terraform plan

# Apply the configuration
terraform apply

# Examine the created infrastructure
ls infrastructure/
ls infrastructure/*/
ls infrastructure/*/servers/
ls infrastructure/*/services/

# View the summary
cat infrastructure/*/SUMMARY.json

# See resource details
terraform show

# Clean up
terraform destroy
```

## What Gets Created

This exercise creates a complete infrastructure simulation:

```
infrastructure/
└── resource-demo-development/
    ├── README.md                    # Project documentation
    ├── network.json                 # Network configuration
    ├── persistent.json              # Persistent configuration
    ├── load-balancer.conf          # Load balancer config
    ├── backup.json                 # Backup config (if enabled)
    ├── .secrets                    # Sensitive data
    ├── SUMMARY.json               # Infrastructure summary
    ├── servers/
    │   ├── server-01.conf         # Individual server configs
    │   ├── server-02.conf
    │   └── server-03.conf
    └── services/
        ├── web.yaml               # Service configurations
        ├── api.yaml
        └── db.yaml
```

## Resource Creation Order

Terraform automatically determines the correct creation order:

1. **project_readme** (no dependencies)
2. **network_config** (depends on project_readme)
3. **server_configs**, **service_configs** (depend on network_config)
4. **backup_config** (conditional, no dependencies)
5. **infrastructure_validation** (depends on configs)
6. **infrastructure_summary** (depends on everything)

## Expected Output

```
resource_summary = {
  "infrastructure" = {
    "network_subnets" = [
      "subnet-1",
      "subnet-2", 
      "subnet-3",
    ]
    "servers" = [
      "resource-demo-development-server-01",
      "resource-demo-development-server-02",
      "resource-demo-development-server-03",
    ]
    "services" = [
      "api",
      "db",
      "web",
    ]
  }
  "project_info" = {
    "environment" = "development"
    "id" = "resource-demo-development"
    "name" = "resource-demo"
  }
  "resources_created" = {
    "backup_enabled" = true
    "server_configs" = 3
    "service_configs" = 3
    "total_files" = 10
  }
}
```

## Exercises to Try

1. **Change Server Count**: Modify `server_count` variable and run `terraform plan` to see what changes

2. **Disable Backup**: Set `enable_backup = false` and see how conditional resources work

3. **Add New Service**: Add a new service to the `server_config` variable

4. **Test Dependencies**: Comment out a `depends_on` and see how Terraform handles it

5. **Lifecycle Rules**: Uncomment the `ignore_changes` in persistent_config and modify content

6. **View Dependency Graph**: Run `terraform graph | dot -Tpng > graph.png` (if graphviz installed)

## Real-World Resource Examples

In actual cloud environments, you'd create resources like:

```hcl
# AWS EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  tags = {
    Name = "WebServer"
  }
}

# Azure Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = "example-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = "Standard_B1s"
}

# Google Cloud Storage Bucket
resource "google_storage_bucket" "static_site" {
  name     = "my-static-site-bucket"
  location = "US"
}

# Kubernetes Deployment
resource "kubernetes_deployment" "app" {
  metadata {
    name = "my-app"
  }
  
  spec {
    replicas = 3
    # ... more configuration
  }
}
```

## Common Resource Patterns

### 1. Environment-Specific Resources
```hcl
resource "aws_instance" "web" {
  count         = var.environment == "production" ? 3 : 1
  instance_type = var.environment == "production" ? "t3.large" : "t3.micro"
}
```

### 2. Resource Tagging
```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_instance" "web" {
  # ... configuration
  tags = local.common_tags
}
```

### 3. Data-Driven Resource Creation
```hcl
variable "servers" {
  type = map(object({
    instance_type = string
    ami           = string
  }))
}

resource "aws_instance" "servers" {
  for_each = var.servers
  
  instance_type = each.value.instance_type
  ami           = each.value.ami
  
  tags = {
    Name = each.key
  }
}
```

## Best Practices

1. **Use Descriptive Names**: Resource names should clearly indicate their purpose
2. **Manage Dependencies**: Let Terraform handle dependencies automatically when possible
3. **Use Variables**: Make resources configurable with variables
4. **Tag Everything**: Use consistent tagging strategies
5. **Lifecycle Management**: Use lifecycle rules for critical resources
6. **State Management**: Understand how Terraform tracks resource state

## Next Steps
- Learn about more complex resource relationships
- Explore provider-specific resources (AWS, Azure, GCP)
- Practice with stateful resources (databases, storage)
- Learn about resource import and migration strategies