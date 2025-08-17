# Critical Fixes Needed for Master Branch

## HIGH PRIORITY - Exercise Breaking Issues

### 1. 01-basics/01-hello-world/main.tf
**Issue**: `local_directory` resource doesn't exist in Terraform local provider
**Lines**: 19-21, and all references
**Fix**:
```hcl
# REMOVE this invalid resource:
resource "local_directory" "lab_directory" {
  path = var.lab_path
}

# The local_file resource creates directories automatically
# Update all references from local_directory.lab_directory.path to var.lab_path
```

### 2. 01-basics/01-hello-world/outputs.tf  
**Issue**: References to non-existent `local_directory` resource
**Lines**: 9, 39, 58, 90
**Fix**:
- Line 9: Change `local_directory.lab_directory.path` to `var.lab_path`
- Line 39: Change `local_directory.lab_directory.path` to `var.lab_path`
- Line 58: Change `local_directory.lab_directory.path` to `var.lab_path`
- Line 90: Change `local_directory.lab_directory.path != null` to `var.lab_path != null`

### 3. 01-basics/01-hello-world/main.tf
**Issue**: Missing variable declaration
**Line**: 133
**Fix**: The terraform_example_tf resource references `var.project_name` which doesn't exist in variables.tf
**Solution**: Add project_name variable to variables.tf

### 4. 01-basics/01-hello-world/outputs.tf
**Issue**: Invalid attribute `content_length` on local_file resource
**Lines**: 74-76
**Fix**: local_file doesn't have content_length attribute. Either remove this output or use length(local_file.xxx.content)

## MEDIUM PRIORITY - Encoding Issues

### 4. Start-TerraformLab.ps1
**Status**: Partially fixed
**Remaining**: Still has some special characters that need replacing

### 5. interactive-guide.ps1 files
**Issue**: UTF-8 encoding problems causing parse errors
**Fix**: Replace all special characters with ASCII equivalents

### 6. Check-Environment.ps1
**Issue**: Syntax errors from encoding
**Fix**: Already partially fixed, needs testing

## Files to Update in Master

```bash
# From master branch:
git checkout master

# Fix the exercise files:
- 01-basics/01-hello-world/main.tf
- 01-basics/01-hello-world/outputs.tf
- 01-basics/01-hello-world/variables.tf (add missing project_name)

# Fix the scripts:
- Start-TerraformLab.ps1 (remaining encoding)
- scripts/Check-Environment.ps1 (test fixes)
- 01-basics/01-hello-world/interactive-guide.ps1
```

## Student Branch Work (DO NOT merge to master)
- jefeh-workspace/* (user workspace, git-ignored)
- mock-terraform.ps1 (testing tool only)
- STUDENT_ISSUES.md (documentation only)
- EXERCISE_ISSUES.md (documentation only)

## VERIFIED FIXES

### Exercise 01-basics/01-hello-world - TESTED AND WORKING
After applying the fixes in the student branch, the exercise now works correctly:
1. `terraform init` - Initializes successfully
2. `terraform plan` - Creates plan for 3 resources
3. `terraform apply` - Creates files successfully with all outputs working
4. `terraform destroy` - Cleans up resources properly

Fixes verified to work:
- Removed invalid `local_directory` resource
- Added missing `project_name` variable
- Fixed `content_length` attribute issue
- All outputs now display correctly