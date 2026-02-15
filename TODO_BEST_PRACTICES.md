# TODO: Apply Best Practices to All Labs

This document tracks which best practices need to be applied to each lab exercise.

## ✅ Completed Labs
- [x] **01-basics/01-hello-world** - Fully updated with best practices
- [x] **01-basics/02-variables** - Template null handling fixed, all patterns applied

## 📝 Labs Requiring Updates

### 01-basics/03-outputs
- [ ] Verify all outputs have descriptions
- [ ] Add sensitive flag where appropriate
- [ ] Create formatted summary output
- [ ] Ensure output files go to `./terraform-lab-output/`
- [ ] Add PowerShell comparison examples
- [ ] Test template files handle null values
- [ ] Verify exercise validates correctly

### 01-basics/04-data-sources
- [ ] Ensure all data sources have clear purposes
- [ ] Add error handling for missing data
- [ ] Create output directory structure
- [ ] Add PowerShell Get-* cmdlet comparisons
- [ ] Include validation examples
- [ ] Test with clean state

### 01-basics/05-resources
- [ ] Group related resources with comments
- [ ] Use clear resource naming conventions
- [ ] Add proper dependencies (implicit and explicit)
- [ ] Ensure outputs to standard directory
- [ ] Add lifecycle examples
- [ ] Include PowerShell New-* comparisons

### 02-providers/01-local-provider
- [ ] Demonstrate all local provider resources
- [ ] Show file/directory patterns
- [ ] Add template file examples
- [ ] Include sensitive file handling
- [ ] Ensure proper output organization
- [ ] Add validation for created files

### 02-providers/06-openstack
- [ ] Review for null value handling in templates
- [ ] Ensure resources are commented for learning
- [ ] Add output directory structure
- [ ] Verify works without real OpenStack
- [ ] Add PowerShell cloud comparisons

### 03-modules/01-simple-module
- [ ] Follow standard module structure
- [ ] Add comprehensive variable validation
- [ ] Include module versioning example
- [ ] Show module source patterns
- [ ] Add output passthrough examples
- [ ] Include PowerShell module comparisons

### 04-state/01-local-state
- [ ] Demonstrate state inspection commands
- [ ] Show state manipulation safely
- [ ] Add state backup examples
- [ ] Include import scenarios
- [ ] Show refresh patterns
- [ ] Compare to PowerShell state tracking

### 06-advanced/02-conditional-resources
- [ ] Show count vs for_each patterns
- [ ] Add dynamic block examples
- [ ] Include conditional expressions
- [ ] Show splat expressions
- [ ] Add template conditionals
- [ ] Compare to PowerShell conditionals

### 07-containers/01-docker-basics
- [ ] Ensure Docker provider examples work
- [ ] Add container lifecycle management
- [ ] Show network and volume patterns
- [ ] Include compose-like configurations
- [ ] Add PowerShell Docker comparisons

## 🔧 Common Updates Needed Across All Labs

### File Structure
- [ ] Ensure all labs use `./terraform-lab-output/` for outputs
- [ ] Create subdirectories for multiple file outputs
- [ ] Clean up any hardcoded paths

### Variables
- [ ] All variables must have descriptions
- [ ] Add validation blocks where appropriate
- [ ] Handle nullable variables in templates
- [ ] Use appropriate variable types
- [ ] Provide sensible defaults

### Outputs
- [ ] All outputs must have descriptions
- [ ] Mark sensitive outputs appropriately
- [ ] Include formatted summary output
- [ ] Show both raw and formatted data

### Documentation
- [ ] Each lab needs clear README.md
- [ ] Include PowerShell comparisons
- [ ] Add troubleshooting section
- [ ] List learning objectives

### Templates
- [ ] Handle null values with conditionals:
  ```hcl
  ${var.value != null ? var.value : "Not configured"}
  ```
- [ ] Use proper template functions
- [ ] Include clear comments

### Validation
- [ ] All exercises must validate after apply
- [ ] Don't require specific resource counts
- [ ] Focus on concept understanding
- [ ] Auto-validate in guided mode

### PowerShell Integration
- [ ] Compare Terraform concepts to PowerShell
- [ ] Use familiar Windows/PowerShell examples
- [ ] Show equivalent PowerShell commands
- [ ] Explain declarative vs imperative

## 🎯 Testing Checklist for Each Lab

Before marking a lab as complete:

```powershell
# 1. Reset and test fresh
.\Start-TerraformLab.ps1 -ResetProgress
.\Start-TerraformLab.ps1 -Exercise "path/to/exercise" -SkipPrerequisites

# 2. Test guided mode
# - Choose option 1 (GUIDED MODE)
# - Complete all steps
# - Verify auto-validation works

# 3. Test manual workflow
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy

# 4. Test reset function
# - Choose option 8 (Reset this exercise)
# - Verify cleanup works

# 5. Check outputs
# - Verify files in ./terraform-lab-output/
# - Check subdirectory organization
# - Confirm no files in temp directories
```

## 📅 Priority Order

1. **High Priority** (Core learning path)
   - 01-basics/03-outputs
   - 01-basics/04-data-sources
   - 01-basics/05-resources

2. **Medium Priority** (Extended learning)
   - 02-providers/01-local-provider
   - 03-modules/01-simple-module
   - 04-state/01-local-state

3. **Lower Priority** (Advanced topics)
   - 06-advanced/02-conditional-resources
   - 07-containers/01-docker-basics
   - 02-providers/06-openstack

## 📊 Progress Tracking

Update this document as each lab is completed:
- Change [ ] to [x] for completed items
- Add notes about any special considerations
- Document any issues found and fixed

## 🐛 Known Issues to Fix

1. **Template Files**: Some labs may have template files that don't handle null values
2. **Output Paths**: Some labs may use different output directories
3. **Validation**: Not all labs may validate correctly after destroy
4. **Prerequisites**: Chain may need adjustment based on complexity

## 📝 Notes

- Focus on educational value over complexity
- Keep examples Windows-friendly
- Ensure all exercises work without cloud accounts
- Test on fresh Windows installations
- Consider PowerShell 5.1 compatibility