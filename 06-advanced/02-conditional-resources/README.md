# Exercise: Advanced Conditional Resources

## Learning Objectives
- Master conditional resource creation patterns
- Learn complex conditional logic with Terraform
- Understand environment-based resource deployment
- Practice feature flag implementation
- Learn dynamic resource group patterns

## Conditional Patterns in Terraform

### Basic Conditional (count)
```hcl
resource "example" "conditional" {
  count = var.enabled ? 1 : 0
  # Resource only created if var.enabled is true
}
```

### Filtered for_each
```hcl
resource "example" "filtered" {
  for_each = {
    for k, v in var.items : 
    k => v if v.enabled
  }
  # Only creates resources for enabled items
}
```

## PowerShell Comparison

```powershell
# PowerShell conditional resource creation
if ($EnableMonitoring) {
    New-MonitoringConfig -Environment $Environment
}

# PowerShell filtered creation
$EnabledFeatures | Where-Object { $_.Enabled } | ForEach-Object {
    New-FeatureConfig -Name $_.Name
}

# PowerShell environment-based logic
$Config = switch ($Environment) {
    "Production" { @{ Replicas = 3; Backup = "hourly" } }
    "Staging"    { @{ Replicas = 2; Backup = "daily" } }
    default      { @{ Replicas = 1; Backup = "weekly" } }
}
```

## Commands to Run

```bash
# Initialize
terraform init

# Plan with default values (development)
terraform plan

# Apply with development settings
terraform apply

# Try production environment
terraform plan -var="environment=production"

# Enable high availability
terraform plan -var="environment=production" -var="enable_high_availability=true"

# Disable features
terraform plan -var="enable_monitoring=false" -var="enable_backups=false"

# Custom feature flags
terraform plan -var='features={logging=true,metrics=false,alerting=true,auto_scaling=false,encryption=true}'

# Clean up
terraform destroy
```

## Conditional Patterns Demonstrated

### 1. Simple Conditionals
Use `count` for basic on/off resources:
```hcl
resource "local_file" "optional" {
  count = var.create_file ? 1 : 0
}
```

### 2. Environment-Based Resources
Different configurations per environment:
```hcl
locals {
  is_production = var.environment == "production"
  instance_type = local.is_production ? "large" : "small"
}
```

### 3. Feature Flags
Enable/disable features dynamically:
```hcl
for_each = {
  for feature, enabled in var.features :
  feature => enabled if enabled
}
```

### 4. Conditional Attributes
Include/exclude configuration sections:
```hcl
monitoring = var.enable_monitoring ? {
  interval = 60
  detailed = true
} : null
```

### 5. Dynamic Resource Counts
Calculate resource count based on conditions:
```hcl
count = local.is_production && var.enable_ha ? 
        max(var.instance_count, 3) : 
        var.instance_count
```

### 6. Conditional Dependencies
Resources that depend on conditional resources:
```hcl
depends_on = [
  local_file.monitoring_config,  # May not exist
  local_file.backup_configs      # May not exist
]
```

## Exercises to Try

### 1. Change Environment
See how resources change with environment:
```bash
terraform plan -var="environment=development"  # Default
terraform plan -var="environment=staging"
terraform plan -var="environment=production"
```

### 2. Toggle Features
Enable/disable individual features:
```bash
# Disable monitoring
terraform apply -var="enable_monitoring=false"

# Enable all features
terraform apply -var='features={logging=true,metrics=true,alerting=true,auto_scaling=true,encryption=true}'
```

### 3. High Availability Mode
Enable HA in production:
```bash
terraform apply -var="environment=production" -var="enable_high_availability=true" -var="instance_count=5"
```

### 4. Minimal Configuration
Run with everything disabled:
```bash
terraform apply \
  -var="enable_monitoring=false" \
  -var="enable_backups=false" \
  -var='features={}'
```

### 5. Add New Conditional
Add a new conditional resource:
```hcl
resource "local_file" "debug_config" {
  count = var.environment == "development" && var.enable_debug ? 1 : 0
  
  filename = "debug.conf"
  content  = "DEBUG=true"
}
```

## Common Conditional Patterns

### Pattern 1: Environment-Specific Resources
```hcl
resource "example" "prod_only" {
  count = var.environment == "production" ? 1 : 0
}
```

### Pattern 2: Gradual Feature Rollout
```hcl
locals {
  feature_enabled = {
    development = true
    staging     = true
    production  = var.feature_flag
  }
}

resource "example" "feature" {
  count = local.feature_enabled[var.environment] ? 1 : 0
}
```

### Pattern 3: Resource Scaling
```hcl
locals {
  instance_count = {
    development = 1
    staging     = 2
    production  = var.enable_ha ? 5 : 3
  }
}

resource "example" "instances" {
  count = local.instance_count[var.environment]
}
```

### Pattern 4: Conditional Modules
```hcl
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"
}
```

### Pattern 5: Dynamic Feature Configuration
```hcl
dynamic "feature" {
  for_each = var.features
  
  content {
    name    = feature.key
    enabled = feature.value
  }
}
```

## Real-World Use Cases

### 1. Cost Optimization
- Smaller resources in development
- No backups in development
- Minimal monitoring in non-production

### 2. Compliance Requirements
- Encryption only in production
- Audit logging in production
- Data retention policies per environment

### 3. Progressive Deployment
- Feature flags for gradual rollout
- A/B testing infrastructure
- Canary deployments

### 4. Disaster Recovery
- HA only in production
- Cross-region replication conditionally
- Backup frequency based on criticality

## Best Practices

### 1. Use Locals for Complex Conditions
```hcl
locals {
  needs_monitoring = var.environment == "production" || var.force_monitoring
  needs_backup = local.needs_monitoring && var.data_criticality == "high"
}
```

### 2. Document Conditional Logic
```hcl
# Only create in production OR if explicitly requested
count = local.is_production || var.force_create ? 1 : 0
```

### 3. Validate Conditional Combinations
```hcl
validation {
  condition = !(var.enable_ha && var.instance_count < 3)
  error_message = "HA requires at least 3 instances"
}
```

### 4. Test All Conditions
- Test with all features enabled
- Test with all features disabled
- Test each environment
- Test edge cases

## Troubleshooting

### Issue: Resource not created
Check conditions:
```bash
terraform console
> var.enable_monitoring
> local.is_production
```

### Issue: Unexpected resource count
Debug with output:
```hcl
output "debug" {
  value = {
    condition = var.enabled
    count = var.enabled ? 1 : 0
  }
}
```

### Issue: Conditional dependency errors
Use splat operator for conditional resources:
```hcl
depends_on = [
  local_file.optional[*]  # Works even if count = 0
]
```

## Next Steps
- Implement conditional modules
- Create environment-specific module configurations
- Build feature flag systems
- Design cost-optimized conditional infrastructure