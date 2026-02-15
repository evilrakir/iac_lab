# ╔════════════════════════════════════════════════════════════════════╗
# ║  TERRAFORM BUILT-IN FUNCTIONS                                   ║
# ║  Master the function library for data transformation            ║
# ╚════════════════════════════════════════════════════════════════════╝

# Terraform includes 100+ built-in functions for string manipulation,
# collection operations, type conversion, and more. This exercise
# demonstrates the most commonly used functions with practical examples.

# POWERSHELL COMPARISON:
# =====================
# Like PowerShell's string methods, array cmdlets, and type operators:
#   PS:  "hello" -replace "l","r"  |  TF: replace("hello", "l", "r")
#   PS:  $array -join ","          |  TF: join(",", var.list)
#   PS:  $hash.Keys                |  TF: keys(var.map)

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
# VARIABLES (data to transform with functions)
# ========================================================================

variable "project_name" {
  description = "Project name with mixed case"
  type        = string
  default     = "My Terraform Project"
}

variable "server_list" {
  description = "List of servers"
  type        = list(string)
  default     = ["web-01", "web-02", "db-01", "app-01", "app-02"]
}

variable "environment_configs" {
  description = "Map of environment configurations"
  type = map(object({
    size     = string
    replicas = number
    region   = string
  }))
  default = {
    dev = {
      size     = "small"
      replicas = 1
      region   = "us-east-1"
    }
    staging = {
      size     = "medium"
      replicas = 2
      region   = "us-east-1"
    }
    prod = {
      size     = "large"
      replicas = 3
      region   = "us-west-2"
    }
  }
}

variable "nested_subnets" {
  description = "Nested subnet configuration"
  type = map(list(string))
  default = {
    public  = ["10.0.1.0/24", "10.0.2.0/24"]
    private = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
    data    = ["10.0.20.0/24"]
  }
}

# ========================================================================
# SECTION 1: STRING FUNCTIONS
# ========================================================================

locals {
  # String manipulation
  lower_name  = lower(var.project_name)           # "my terraform project"
  upper_name  = upper(var.project_name)           # "MY TERRAFORM PROJECT"
  title_name  = title(var.project_name)           # "My Terraform Project"
  trimmed     = trimspace("  hello  ")            # "hello"
  replaced    = replace(var.project_name, " ", "-") # "My-Terraform-Project"
  slug        = lower(replace(var.project_name, " ", "-")) # "my-terraform-project"

  # Format strings (like PowerShell's -f operator)
  formatted = format("Project: %s, Servers: %d", var.project_name, length(var.server_list))
  padded    = format("%-20s | %5d replicas", "production", 3)

  # String testing
  has_web    = startswith(var.server_list[0], "web")  # true
  has_suffix = endswith("config.json", ".json")        # true
  contains_db = contains(var.server_list, "db-01")    # true

  # Regex
  regex_match = regex("^(\\w+)-(\\d+)$", "web-01")  # ["web", "01"]

  # Join and split
  joined  = join(", ", var.server_list)              # "web-01, web-02, ..."
  split_result = split("-", "web-01")                # ["web", "01"]

  # Substring
  substr_result = substr("Hello World", 0, 5)       # "Hello"
}

resource "local_file" "string_functions" {
  filename = "./terraform-lab-output/functions/string-functions.json"
  content = jsonencode({
    title = "String Functions Demo"
    results = {
      lower          = local.lower_name
      upper          = local.upper_name
      title          = local.title_name
      trimspace      = local.trimmed
      replace        = local.replaced
      slug           = local.slug
      format         = local.formatted
      format_padded  = local.padded
      startswith     = local.has_web
      endswith       = local.has_suffix
      contains       = local.contains_db
      join           = local.joined
      split          = local.split_result
      substr         = local.substr_result
    }
    powershell_equivalents = {
      lower     = "$string.ToLower()"
      upper     = "$string.ToUpper()"
      replace   = "$string -replace ' ','-'"
      format    = "\"Project: {0}, Servers: {1}\" -f $name, $count"
      join      = "$array -join ', '"
      split     = "'web-01' -split '-'"
      contains  = "$array -contains 'db-01'"
      startswith = "$string.StartsWith('web')"
      substr    = "$string.Substring(0, 5)"
    }
  })
}

# ========================================================================
# SECTION 2: COLLECTION FUNCTIONS
# ========================================================================

locals {
  # List operations
  list_length   = length(var.server_list)                    # 5
  first_server  = element(var.server_list, 0)                # "web-01"
  web_servers   = [for s in var.server_list : s if startswith(s, "web")]
  sorted        = sort(var.server_list)
  reversed      = reverse(var.server_list)
  unique_types  = distinct([for s in var.server_list : split("-", s)[0]])
  sliced        = slice(var.server_list, 0, 2)               # first 2

  # Map operations
  env_keys      = keys(var.environment_configs)               # ["dev", "staging", "prod"]
  env_values    = values(var.environment_configs)
  dev_config    = lookup(var.environment_configs, "dev", null)
  merged_tags   = merge(
    { ManagedBy = "terraform" },
    { Environment = "dev" },
    { Team = "infra" }
  )

  # Flatten nested structures
  all_subnets = flatten(values(var.nested_subnets))

  # Zipmap (combine two lists into a map)
  server_indices = zipmap(var.server_list, range(length(var.server_list)))
}

resource "local_file" "collection_functions" {
  filename = "./terraform-lab-output/functions/collection-functions.json"
  content = jsonencode({
    title = "Collection Functions Demo"
    list_results = {
      length        = local.list_length
      element_0     = local.first_server
      web_servers   = local.web_servers
      sorted        = local.sorted
      reversed      = local.reversed
      unique_types  = local.unique_types
      sliced        = local.sliced
    }
    map_results = {
      keys          = local.env_keys
      lookup_dev    = local.dev_config
      merged        = local.merged_tags
    }
    advanced = {
      flattened     = local.all_subnets
      zipmap        = local.server_indices
    }
    powershell_equivalents = {
      length     = "$array.Count"
      element    = "$array[0]"
      where      = "$array | Where-Object { $_ -like 'web*' }"
      sort       = "$array | Sort-Object"
      unique     = "$array | Select-Object -Unique"
      keys       = "$hash.Keys"
      values     = "$hash.Values"
      merge      = "$hash1 + $hash2"
      flatten    = "$nestedArray | ForEach-Object { $_ }"
    }
  })
}

# ========================================================================
# SECTION 3: NUMERIC AND TYPE FUNCTIONS
# ========================================================================

locals {
  # Numeric
  max_val   = max(1, 5, 3)         # 5
  min_val   = min(1, 5, 3)         # 1
  abs_val   = abs(-42)             # 42
  ceil_val  = ceil(4.3)            # 5
  floor_val = floor(4.7)           # 4
  signum_val = signum(-10)         # -1

  # Type conversion
  to_string = tostring(42)         # "42"
  to_number = tonumber("42")       # 42
  to_list   = tolist(toset(["a", "b", "a"]))  # ["a", "b"]
  to_set    = toset(["a", "b", "a"])           # ["a", "b"]

  # Encoding
  json_encoded = jsonencode({ name = "test", count = 42 })
  base64_val   = base64encode("Hello Terraform")
}

resource "local_file" "type_functions" {
  filename = "./terraform-lab-output/functions/type-and-numeric-functions.json"
  content = jsonencode({
    title = "Numeric and Type Functions"
    numeric = {
      max    = local.max_val
      min    = local.min_val
      abs    = local.abs_val
      ceil   = local.ceil_val
      floor  = local.floor_val
    }
    type_conversion = {
      tostring    = local.to_string
      tonumber    = local.to_number
      tolist      = local.to_list
    }
    encoding = {
      jsonencode  = local.json_encoded
      base64      = local.base64_val
    }
  })
}

# ========================================================================
# SECTION 4: PRACTICAL PATTERNS
# ========================================================================

resource "local_file" "practical_patterns" {
  filename = "./terraform-lab-output/functions/practical-patterns.tf"
  content  = <<-EOT
    # ============================================
    # PRACTICAL FUNCTION PATTERNS
    # ============================================

    # --- Pattern 1: Generate resource names ---
    locals {
      name_prefix = lower(replace(var.project, " ", "-"))
      resource_name = "$${local.name_prefix}-$${var.environment}-$${var.region}"
      # Result: "my-project-prod-us-east-1"
    }

    # --- Pattern 2: Conditional defaults ---
    locals {
      instance_type = coalesce(var.instance_type, "t3.medium")
      # Returns first non-null/non-empty value
      # Like: $value ?? "default" in PowerShell 7+
    }

    # --- Pattern 3: Filter and transform lists ---
    locals {
      private_subnets = [
        for subnet in var.subnets :
        subnet if subnet.type == "private"
      ]
      subnet_ids = [for s in local.private_subnets : s.id]
    }

    # --- Pattern 4: Build tags from multiple sources ---
    locals {
      common_tags = merge(
        var.default_tags,
        var.environment_tags,
        {
          Name      = local.resource_name
          Timestamp = timestamp()
        }
      )
    }

    # --- Pattern 5: CIDR calculations ---
    locals {
      vpc_cidr    = "10.0.0.0/16"
      subnet_cidr = cidrsubnet(local.vpc_cidr, 8, 1)  # "10.0.1.0/24"
      # cidrsubnet(prefix, newbits, netnum)
    }

    # --- Pattern 6: Lookup with fallback ---
    locals {
      ami_map = {
        us-east-1 = "ami-12345678"
        us-west-2 = "ami-87654321"
      }
      ami = lookup(local.ami_map, var.region, "ami-00000000")
    }

    # --- Pattern 7: Try/can for error handling ---
    locals {
      parsed = try(jsondecode(var.config_json), {})
      # Returns {} if JSON is invalid instead of error
      # Like: try { $json | ConvertFrom-Json } catch { @{} }
    }
  EOT
}

# ========================================================================
# SECTION 5: POWERSHELL COMPARISON
# ========================================================================

resource "local_file" "powershell_comparison" {
  filename = "./terraform-lab-output/terraform-vs-powershell-functions.ps1"
  content  = <<-EOT
    # Terraform Functions vs PowerShell Equivalents
    # ===============================================

    # STRING FUNCTIONS
    Write-Host "=== String Functions ===" -ForegroundColor Yellow

    # lower() / upper() / title()
    "Hello World".ToLower()       # terraform: lower("Hello World")
    "Hello World".ToUpper()       # terraform: upper("Hello World")
    (Get-Culture).TextInfo.ToTitleCase("hello world")  # terraform: title()

    # replace()
    "hello world" -replace "world","terraform"  # terraform: replace("hello world", "world", "terraform")

    # join() / split()
    @("a","b","c") -join ","     # terraform: join(",", ["a","b","c"])
    "a,b,c" -split ","           # terraform: split(",", "a,b,c")

    # format()
    "Server {0}: {1} replicas" -f "web-01", 3  # terraform: format("Server %s: %d replicas", "web-01", 3)

    # COLLECTION FUNCTIONS
    Write-Host "`n=== Collection Functions ===" -ForegroundColor Yellow

    # length()
    @(1,2,3).Count                # terraform: length([1,2,3])

    # contains()
    @(1,2,3) -contains 2         # terraform: contains([1,2,3], 2)

    # keys() / values()
    $$hash = @{a=1; b=2}
    $$hash.Keys                   # terraform: keys(var.map)
    $$hash.Values                 # terraform: values(var.map)

    # merge()
    $$hash1 = @{a=1; b=2}
    $$hash2 = @{c=3; d=4}
    $$merged = $$hash1 + $$hash2  # terraform: merge(map1, map2)

    # flatten()
    @(@(1,2), @(3,4)) | ForEach-Object { $$_ }  # terraform: flatten([[1,2],[3,4]])

    # sort()
    @(3,1,2) | Sort-Object       # terraform: sort([3,1,2])

    # NUMERIC FUNCTIONS
    Write-Host "`n=== Numeric Functions ===" -ForegroundColor Yellow

    [Math]::Max(1, 5)            # terraform: max(1, 5)
    [Math]::Min(1, 5)            # terraform: min(1, 5)
    [Math]::Abs(-42)             # terraform: abs(-42)
    [Math]::Ceiling(4.3)         # terraform: ceil(4.3)
    [Math]::Floor(4.7)           # terraform: floor(4.7)

    # TYPE CONVERSION
    Write-Host "`n=== Type Conversion ===" -ForegroundColor Yellow

    [string]42                    # terraform: tostring(42)
    [int]"42"                     # terraform: tonumber("42")
    @{a=1} | ConvertTo-Json      # terraform: jsonencode({a=1})
    [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("hello"))  # terraform: base64encode("hello")

    Write-Host "`nKey Insight:" -ForegroundColor Cyan
    Write-Host "  Terraform has 100+ built-in functions"
    Write-Host "  Most map directly to PowerShell equivalents"
    Write-Host "  Use 'terraform console' to test functions interactively"
    Write-Host "  Try: terraform console, then type: upper(\"hello\")"
  EOT
}

# ========================================================================
# OUTPUTS
# ========================================================================

output "string_demo" {
  description = "String function results"
  value = {
    slug    = local.slug
    format  = local.formatted
    joined  = local.joined
  }
}

output "collection_demo" {
  description = "Collection function results"
  value = {
    web_servers  = local.web_servers
    unique_types = local.unique_types
    env_keys     = local.env_keys
    all_subnets  = local.all_subnets
  }
}

output "lesson_summary" {
  description = "Key takeaways"
  value = {
    strings     = "lower(), upper(), replace(), join(), split(), format()"
    collections = "length(), keys(), values(), merge(), flatten(), lookup()"
    numeric     = "max(), min(), abs(), ceil(), floor()"
    types       = "tostring(), tonumber(), tolist(), toset(), jsonencode()"
    testing     = "Use 'terraform console' to interactively test functions"
    error_handling = "try() and can() for graceful error handling"
  }
}
