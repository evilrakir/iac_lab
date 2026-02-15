# ╔════════════════════════════════════════════════════════════════════╗
# ║  DYNAMIC BLOCKS                                                  ║
# ║  Status: Coming Soon                                              ║
# ╚════════════════════════════════════════════════════════════════════╝

# This exercise is under development.
#
# WHAT YOU WILL LEARN:
# - Dynamic block syntax for generating repeated nested blocks
# - Using for_each within dynamic blocks
# - When to use dynamic blocks vs static repetition
# - Nested dynamic blocks for complex resources
#
# PREREQUISITES:
# - 06-advanced/02-conditional-resources
#
# POWERSHELL COMPARISON:
# Like ForEach-Object generating dynamic configuration sections -
# building repetitive structure from data.

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.0"
}

resource "local_file" "coming_soon" {
  filename = "./terraform-lab-output/coming-soon.txt"
  content  = <<-EOT
    This exercise is coming soon!

    Topic: Dynamic Blocks

    Check back for updates or contribute at:
    https://github.com/evilrakir/iac_lab
  EOT
}

output "status" {
  description = "Exercise status"
  value       = "Coming Soon - Dynamic Blocks"
}
