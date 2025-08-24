# 🎓 Terraform Learning Guide for PowerShell Admins

## What You're About to Learn

This guide will walk you through Terraform concepts by comparing them to PowerShell concepts you already know. By the end, you'll understand what each command does and why.

## 📚 Core Concepts

### 1. Declarative vs Imperative

**PowerShell (Imperative):**
```powershell
# Step 1: Check if file exists
if (Test-Path "welcome.txt") {
    # Step 2: Delete it
    Remove-Item "welcome.txt"
}
# Step 3: Create new file
New-Item -Path "welcome.txt" -ItemType File -Value "Hello World"
```

**Terraform (Declarative):**
```hcl
# Just describe what you want - Terraform figures out how to get there
resource "local_file" "welcome_file" {
  filename = "welcome.txt"
  content  = "Hello World"
}
```

### 2. Variables (PowerShell Parameters)

**PowerShell:**
```powershell
param(
    [string]$StudentName = "Default Student",
    [string]$Environment = "development"
)
```

**Terraform:**
```hcl
variable "student_name" {
  description = "Your name for personalizing the lab"
  type        = string
  default     = "Default Student"
}

variable "environment" {
  description = "Environment type"
  type        = string
  default     = "development"
}
```

### 3. Resources (PowerShell New-* cmdlets)

**PowerShell:**
```powershell
New-Item -Path "output.txt" -ItemType File -Value "Some content"
```

**Terraform:**
```hcl
resource "local_file" "output_file" {
  filename = "output.txt"
  content  = "Some content"
}
```

## 🚀 Step-by-Step Learning Process

### Step 1: Understand the Files

Before running any commands, let's understand what each file does:

1. **`main.tf`** - This is like your main PowerShell script
2. **`variables.tf`** - This is like your param() block
3. **`terraform.tfstate`** - This tracks what Terraform has created (like a log file)

### Step 2: The Terraform Workflow

Terraform has a specific workflow (like PowerShell's Write-Host -> Execute -> Check):

1. **`terraform init`** - Downloads providers (like Install-Module)
2. **`terraform plan`** - Shows what will happen (like -WhatIf)
3. **`terraform apply`** - Creates the resources (like running your script)
4. **`terraform show`** - Shows current state (like Get-ChildItem)

### Step 3: What Each Command Does

**`terraform init`:**
- Downloads the "local" provider (like installing a PowerShell module)
- Sets up the working directory
- Creates `.terraform` folder (like module cache)

**`terraform plan`:**
- Reads your .tf files
- Compares with current state
- Shows what will be created/changed/deleted
- **Does NOT make any changes**

**`terraform apply`:**
- Actually creates the resources
- Updates the state file
- Shows you what was created

**`terraform show`:**
- Shows the current state
- Lists all resources Terraform is managing

## 🔍 Let's Examine the Files

### What's in main.tf?

The main.tf file creates three things:
1. A welcome text file
2. A PowerShell script showing Terraform concepts
3. An example Terraform configuration file

Each `resource` block is like a PowerShell command that creates something.

### What's in variables.tf?

This file defines all the input parameters, just like a PowerShell script's param() block. It includes:
- String variables (like [string] parameters)
- Number variables (like [int] parameters)
- Boolean variables (like [switch] parameters)
- Lists and maps (like arrays and hashtables)

## 🎯 Your Learning Path

1. **Read the files first** - Understand what they do
2. **Run `terraform init`** - Set up the environment
3. **Run `terraform plan`** - See what will happen
4. **Run `terraform apply`** - Create the resources
5. **Examine the output** - See what was created
6. **Try modifying the files** - Change variables and see what happens

## 💡 Pro Tips

- **Always run `plan` before `apply`** - It's like using -WhatIf
- **The state file is important** - Don't delete it manually
- **Variables make your code reusable** - Like PowerShell parameters
- **Resources are declarative** - Describe what you want, not how to do it

## 🆘 When You Get Stuck

1. **Read the error messages carefully** - They're usually helpful
2. **Check the Terraform documentation** - It's excellent
3. **Compare to PowerShell** - Many concepts are similar
4. **Use `terraform plan`** - It shows you exactly what will happen

## 🎉 Next Steps

After completing this exercise, you'll understand:
- How Terraform files are structured
- What each command does
- How variables work
- How to create simple resources
- The basic Terraform workflow

Ready to start? Let's begin with understanding the files, then run the commands!
