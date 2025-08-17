# Exercise 4: Terraform Data Sources

## Learning Objectives
- Understand what data sources are and how they differ from resources
- Learn to read existing files and configuration with data sources
- Practice processing and transforming data from external sources
- See how data sources integrate with resource creation
- Learn about sensitive data handling

## What Are Data Sources?
Data sources in Terraform allow you to **read** information from existing infrastructure, files, or external systems. Unlike resources (which create/manage infrastructure), data sources are **read-only**.

Think of data sources as "GET" operations that fetch information you can use in your configuration.

## PowerShell Analogy
```powershell
# PowerShell reading existing data
$existingConfig = Get-Content "config.json" | ConvertFrom-Json  # Like data source
$servers = Import-Csv "servers.csv"                            # Like data source

# Then use that data to create new things
foreach ($server in $servers) {
    if ($server.Status -eq "active") {
        New-Item "server-$($server.Name).conf" -Force  # Like Terraform resource
    }
}
```

## Key Concepts Demonstrated

### 1. Data Source Types
- **File Reading**: Reading JSON, CSV, and text files
- **Data Processing**: Parsing and transforming the read data  
- **Conditional Logic**: Filtering data based on conditions
- **Data Integration**: Using data sources to create new resources

### 2. Data Source vs Resource
```hcl
# RESOURCE - Creates/manages something
resource "local_file" "new_file" {
  filename = "created-by-terraform.txt"
  content  = "This file was created"
}

# DATA SOURCE - Reads existing something  
data "local_file" "existing_file" {
  filename = "already-exists.txt"  # Must already exist
}
```

### 3. Data Processing Patterns
- **JSON Parsing**: `jsondecode(data.local_file.config.content)`
- **String Processing**: `split()`, `trimspace()`, filtering
- **Data Transformation**: Converting formats, filtering active items
- **Conditional Creation**: Creating resources based on data source content

## Commands to Run

```bash
# Initialize the exercise
terraform init

# See what will be created (including data source reads)
terraform plan

# Apply the configuration
terraform apply

# View the processed data
terraform output

# Look at generated files
ls output/
cat output/processed-config.json
cat output/server-web-01.conf

# See sensitive output (environment variables)
terraform output environment_variables

# Clean up
terraform destroy
```

## What Gets Created

This exercise creates several files first, then reads them back as data sources:

**Created as Resources (simulating existing infrastructure):**
- `data/app-config.json` - Application configuration
- `data/servers.csv` - Server inventory  
- `data/secrets.env` - Environment variables
- `data/manifest.txt` - Directory listing

**Read as Data Sources:**
- The same files are then read back using `data "local_file"` blocks

**Generated from Data Sources:**
- `output/processed-config.json` - Processed configuration
- `output/server-*.conf` - Individual server config files

## Expected Output

After running `terraform apply`, you'll see outputs like:

```
original_config_summary = {
  "app_name" = "data-sources-demo"
  "app_port" = 8080
  "app_version" = "1.2.3"
  "environment" = "development"
  "features" = {
    "authentication" = true
    "caching" = false
    "logging" = true
    "monitoring" = true
  }
  "region" = "us-east-1"
}

server_inventory_summary = {
  "active_servers" = [
    "web-01",
    "web-02", 
    "db-01",
    "api-01",
  ]
  "server_roles" = [
    "api",
    "database", 
    "webserver",
  ]
  "total_servers" = 4
}

processed_data = {
  "environment_vars_count" = 4
  "features_enabled" = [
    "authentication",
    "logging",
    "monitoring",
  ]
  "generated_files" = 5
  "servers_by_role" = {
    "api" = [
      "api-01",
    ]
    "database" = [
      "db-01", 
    ]
    "webserver" = [
      "web-01",
      "web-02",
    ]
  }
}
```

## Exercises to Try

1. **Modify Server Data**: Edit `data/servers.csv` and run `terraform plan` to see how it affects the output

2. **Add New Features**: Modify the JSON config to add new features and see how they're processed

3. **Filter Different Servers**: Change the filtering logic to exclude different server types

4. **Add New Data Source**: Create a new file and add a data source to read it

5. **Process Different Formats**: Try reading YAML or other file formats

## Real-World Data Source Examples

In actual cloud environments, you'd use data sources like:

```hcl
# Read existing AWS VPC
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["production-vpc"]
  }
}

# Read latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Read DNS zone
data "aws_route53_zone" "main" {
  name = "example.com"
}

# Read Kubernetes config
data "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = "production"
  }
}
```

## Common Use Cases

Data sources are essential for:
- **Infrastructure Discovery**: Finding existing resources to integrate with
- **Configuration Management**: Reading external config files
- **Security**: Fetching secrets from external systems
- **Compliance**: Reading security policies and applying them
- **Integration**: Connecting with existing systems and databases

## Next Steps
- Learn about more complex data source scenarios
- Try data sources with cloud providers (AWS, Azure, GCP)
- Explore data source filtering and querying capabilities
- Practice combining multiple data sources in one configuration