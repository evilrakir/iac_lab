# Exercise: AWS Provider Basics - Introduction to Cloud Infrastructure
# Learn AWS provider configuration and basic resource management

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

# Variables
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "terraform-aws-basics"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "learning"
}

variable "enable_vpc_creation" {
  description = "Enable VPC creation (requires AWS credentials)"
  type        = bool
  default     = false
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  
  # In a learning environment, you might not have AWS credentials
  # This configuration shows how it would be set up
  
  # For production, use one of these methods:
  # 1. AWS credentials file (~/.aws/credentials)
  # 2. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
  # 3. IAM roles (when running on EC2)
  # 4. AWS SSO
  
  # For this demo, we'll create local files showing what would be created
  # Set enable_vpc_creation = true if you have AWS credentials configured
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Network configuration
  vpc_cidr = "10.0.0.0/16"
  
  # Availability zones (would be fetched from AWS in real scenario)
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  
  # Subnet configuration
  public_subnets = [
    {
      cidr = "10.0.1.0/24"
      az   = local.availability_zones[0]
      name = "public-1"
    },
    {
      cidr = "10.0.2.0/24"
      az   = local.availability_zones[1]
      name = "public-2"
    }
  ]
  
  private_subnets = [
    {
      cidr = "10.0.11.0/24"
      az   = local.availability_zones[0]
      name = "private-1"
    },
    {
      cidr = "10.0.12.0/24"
      az   = local.availability_zones[1]
      name = "private-2"
    }
  ]
}

# AWS Data Sources (read-only, work without credentials in some cases)
data "aws_availability_zones" "available" {
  state = "available"
  
  # This will only work if AWS credentials are configured
  # We'll handle the error gracefully with local fallback
}

data "aws_region" "current" {
  # This also requires credentials
}

# CONDITIONAL AWS RESOURCES (only created if credentials are available)

# VPC - Virtual Private Cloud
resource "aws_vpc" "main" {
  count = var.enable_vpc_creation ? 1 : 0
  
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count = var.enable_vpc_creation ? 1 : 0
  
  vpc_id = aws_vpc.main[0].id
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = var.enable_vpc_creation ? length(local.public_subnets) : 0
  
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = local.public_subnets[count.index].cidr
  availability_zone       = local.public_subnets[count.index].az
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${local.public_subnets[count.index].name}"
    Type = "Public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = var.enable_vpc_creation ? length(local.private_subnets) : 0
  
  vpc_id            = aws_vpc.main[0].id
  cidr_block        = local.private_subnets[count.index].cidr
  availability_zone = local.private_subnets[count.index].az
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${local.private_subnets[count.index].name}"
    Type = "Private"
  })
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  count = var.enable_vpc_creation ? 1 : 0
  
  vpc_id = aws_vpc.main[0].id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

# Associate Public Subnets with Route Table
resource "aws_route_table_association" "public" {
  count = var.enable_vpc_creation ? length(aws_subnet.public) : 0
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Security Group
resource "aws_security_group" "web" {
  count = var.enable_vpc_creation ? 1 : 0
  
  name_prefix = "${var.project_name}-web"
  vpc_id      = aws_vpc.main[0].id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-sg"
  })
}

# DEMONSTRATION FILES (created regardless of AWS credentials)

# AWS Infrastructure Plan (what would be created)
resource "local_file" "aws_infrastructure_plan" {
  filename = "${path.module}/aws-plan.json"
  content = jsonencode({
    project = {
      name        = var.project_name
      environment = var.environment
      region      = var.aws_region
    }
    
    network = {
      vpc_cidr        = local.vpc_cidr
      public_subnets  = local.public_subnets
      private_subnets = local.private_subnets
    }
    
    resources_planned = {
      vpc                = 1
      internet_gateway   = 1
      public_subnets     = length(local.public_subnets)
      private_subnets    = length(local.private_subnets)
      route_tables       = 1
      security_groups    = 1
      route_associations = length(local.public_subnets)
    }
    
    tags = local.common_tags
    
    estimated_monthly_cost = {
      vpc                = 0      # Free
      internet_gateway   = 0      # Free  
      subnets           = 0      # Free
      route_tables      = 0      # Free
      security_groups   = 0      # Free
      note              = "Basic networking components are free in AWS"
    }
  })
}

# Terraform Configuration Example
resource "local_file" "terraform_aws_example" {
  filename = "${path.module}/terraform-aws-example.tf"
  content = <<-EOT
    # Example AWS Terraform Configuration
    # This shows what a real AWS setup might look like
    
    terraform {
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 5.0"
        }
      }
    }
    
    # Provider configuration
    provider "aws" {
      region = "us-east-1"
      
      # Authentication methods (choose one):
      # 1. AWS CLI: aws configure
      # 2. Environment variables:
      #    export AWS_ACCESS_KEY_ID="..."
      #    export AWS_SECRET_ACCESS_KEY="..."
      # 3. IAM roles (when running on EC2)
      # 4. AWS credentials file
    }
    
    # Data sources to read existing AWS resources
    data "aws_availability_zones" "available" {
      state = "available"
    }
    
    data "aws_ami" "ubuntu" {
      most_recent = true
      owners      = ["099720109477"] # Canonical
      
      filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
      }
    }
    
    # VPC Resource
    resource "aws_vpc" "main" {
      cidr_block           = "10.0.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
      
      tags = {
        Name = "main-vpc"
      }
    }
    
    # Subnet Resource
    resource "aws_subnet" "public" {
      vpc_id                  = aws_vpc.main.id
      cidr_block              = "10.0.1.0/24"
      availability_zone       = data.aws_availability_zones.available.names[0]
      map_public_ip_on_launch = true
      
      tags = {
        Name = "public-subnet"
      }
    }
    
    # EC2 Instance Resource
    resource "aws_instance" "web" {
      ami           = data.aws_ami.ubuntu.id
      instance_type = "t3.micro"
      subnet_id     = aws_subnet.public.id
      
      tags = {
        Name = "web-server"
      }
    }
  EOT
}

# AWS Best Practices Guide
resource "local_file" "aws_best_practices" {
  filename = "${path.module}/AWS_BEST_PRACTICES.md"
  content = <<-EOT
    # AWS Terraform Best Practices
    
    ## Authentication
    
    ### 1. AWS CLI (Recommended for development)
    ```bash
    aws configure
    # Enter your Access Key ID, Secret Access Key, and default region
    ```
    
    ### 2. Environment Variables
    ```bash
    export AWS_ACCESS_KEY_ID="your-access-key"
    export AWS_SECRET_ACCESS_KEY="your-secret-key"
    export AWS_DEFAULT_REGION="us-east-1"
    ```
    
    ### 3. IAM Roles (Recommended for production)
    - Attach IAM roles to EC2 instances
    - Use AWS EKS service accounts
    - No long-term credentials needed
    
    ## Resource Naming
    
    Use consistent naming conventions:
    ```hcl
    resource "aws_vpc" "main" {
      tags = {
        Name        = "$${var.project_name}-vpc"
        Environment = var.environment
        Project     = var.project_name
        ManagedBy   = "Terraform"
      }
    }
    ```
    
    ## Cost Management
    
    - Use `t3.micro` instances (free tier eligible)
    - Enable detailed monitoring selectively
    - Use lifecycle rules for S3
    - Tag resources for cost allocation
    
    ## Security Best Practices
    
    ### 1. Least Privilege Access
    ```hcl
    resource "aws_security_group" "web" {
      name_prefix = "web-"
      
      ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Only if needed
      }
    }
    ```
    
    ### 2. Encryption
    ```hcl
    resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
      bucket = aws_s3_bucket.example.id
      
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
      }
    }
    ```
    
    ## State Management
    
    ### Remote State with S3
    ```hcl
    terraform {
      backend "s3" {
        bucket = "my-terraform-state"
        key    = "project/terraform.tfstate"
        region = "us-east-1"
      }
    }
    ```
    
    ## Common AWS Resources
    
    ### Compute
    - `aws_instance` - EC2 instances
    - `aws_launch_template` - Launch templates
    - `aws_autoscaling_group` - Auto scaling
    - `aws_lambda_function` - Serverless functions
    
    ### Networking
    - `aws_vpc` - Virtual Private Cloud
    - `aws_subnet` - Subnets
    - `aws_security_group` - Security groups
    - `aws_route_table` - Route tables
    - `aws_internet_gateway` - Internet gateway
    
    ### Storage
    - `aws_s3_bucket` - Object storage
    - `aws_ebs_volume` - Block storage
    - `aws_efs_file_system` - File system
    
    ### Database
    - `aws_db_instance` - RDS databases
    - `aws_dynamodb_table` - NoSQL database
    
    ## Troubleshooting
    
    ### Common Issues
    1. **Credentials**: Verify AWS credentials are configured
    2. **Permissions**: Ensure IAM user has required permissions
    3. **Regions**: Check if resources exist in the correct region
    4. **Quotas**: Verify service limits haven't been exceeded
    
    ### Debug Commands
    ```bash
    # Test AWS credentials
    aws sts get-caller-identity
    
    # List available regions
    aws ec2 describe-regions
    
    # Terraform debug
    export TF_LOG=DEBUG
    terraform plan
    ```
  EOT
}

# Output information about AWS provider setup
output "aws_provider_info" {
  description = "Information about AWS provider configuration"
  value = {
    provider_version = "~> 5.0"
    region_configured = var.aws_region
    vpc_creation_enabled = var.enable_vpc_creation
    
    # This will only work if AWS credentials are available
    aws_data_available = var.enable_vpc_creation
    
    files_created = {
      infrastructure_plan = local_file.aws_infrastructure_plan.filename
      terraform_example   = local_file.terraform_aws_example.filename
      best_practices      = local_file.aws_best_practices.filename
    }
  }
}

output "aws_infrastructure_summary" {
  description = "Summary of planned AWS infrastructure"
  value = var.enable_vpc_creation ? {
    vpc_created = length(aws_vpc.main) > 0
    vpc_id = length(aws_vpc.main) > 0 ? aws_vpc.main[0].id : null
    public_subnets = length(aws_subnet.public)
    private_subnets = length(aws_subnet.private)
    security_groups = length(aws_security_group.web)
  } : {
    note = "Set enable_vpc_creation = true and configure AWS credentials to create real resources"
    planned_resources = {
      vpc = 1
      public_subnets = length(local.public_subnets)
      private_subnets = length(local.private_subnets)
      security_groups = 1
    }
  }
}

output "next_steps" {
  description = "Next steps for AWS learning"
  value = <<-EOT
    
    AWS PROVIDER NEXT STEPS:
    
    1. CONFIGURE AWS CREDENTIALS:
       - Install AWS CLI: https://aws.amazon.com/cli/
       - Run: aws configure
       - Or set environment variables
    
    2. ENABLE REAL RESOURCE CREATION:
       - Set enable_vpc_creation = true
       - Run: terraform plan
       - Run: terraform apply
    
    3. EXPLORE AWS RESOURCES:
       - EC2 instances
       - S3 buckets  
       - RDS databases
       - Lambda functions
    
    4. LEARN COST MANAGEMENT:
       - Use AWS Free Tier
       - Set up billing alerts
       - Tag resources for cost tracking
    
    5. PRACTICE SECURITY:
       - IAM roles and policies
       - Security groups
       - VPC design
    
    Files created for learning: 3
    AWS credentials required: ${var.enable_vpc_creation}
    
  EOT
}