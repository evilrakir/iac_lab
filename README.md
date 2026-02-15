# 🚀 Modern Infrastructure as Code for Windows Admins
## Terraform Mastery Course - Interactive Lab

[![Terraform](https://img.shields.io/badge/Terraform-v1.0%2B-623CE4?logo=terraform)](https://www.terraform.io/)
[![Windows](https://img.shields.io/badge/Windows-Compatible-0078D6?logo=windows)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-Native-5391FE?logo=powershell)](https://docs.microsoft.com/powershell/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Enabled-326CE5?logo=kubernetes)](https://kubernetes.io/)

Welcome to the **Interactive Terraform Learning Lab** designed specifically for Windows administrators transitioning to modern Infrastructure as Code practices!

## 🎯 What Makes This Lab Special?

- **🪟 Windows-First Design**: Built by Windows admins, for Windows admins
- **🎮 Interactive Learning**: Guided exercises with real-time validation
- **📊 Progress Tracking**: Achievement system and completion certificates
- **🔧 PowerShell Native**: All automation in familiar PowerShell
- **🚀 Modern & Legacy**: Covers both cutting-edge and enterprise reality
- **💡 Smart Hints**: Get help when you're stuck
- **✅ No Admin Required**: Learn without elevation (mostly!)

## 📖 Best Practices

**Important**: Please review [BEST_PRACTICES.md](BEST_PRACTICES.md) for:
- Common issues and solutions
- Command workflow guidelines
- Exercise validation tips
- Development best practices

## 🏃 Quick Start

```powershell
# 1. Clone the repository
git clone https://github.com/evilrakir/iac_lab.git
cd iac_lab

# 2. Start the interactive lab
.\Start-TerraformLab.ps1

# View your progress
.\Start-TerraformLab.ps1 -ShowStats

# Reset all progress and start fresh
.\Start-TerraformLab.ps1 -ResetProgress

# Skip prerequisites (for testing)
.\Start-TerraformLab.ps1 -SkipPrerequisites

# Start a specific exercise
.\Start-TerraformLab.ps1 -Exercise "01-basics/02-variables"
```

That's it! The interactive system will guide you through everything else.

## 📚 What You'll Learn

### Core Skills (Everyone)
- ✅ Terraform fundamentals and syntax
- ✅ Variables, outputs, and state management
- ✅ Modules and reusable components
- ✅ Best practices and patterns

### Modern Technologies (Priority)
- 🐋 Docker container management with Terraform
- ☸️ Kubernetes deployments and configurations
- 🔄 CI/CD pipeline integration
- 🔗 Ansible + Terraform integration
- ☁️ Multi-cloud deployments (AWS, Azure, GCP)

### Legacy/Enterprise (Optional)
- 📦 Vagrant (marked as legacy)
- 👴 Chef/Puppet (traditional config management)
- 🖥️ On-premise virtualization

## 🎓 Learning Path

```mermaid
graph LR
    A[01-Basics] --> B[02-Providers]
    B --> C[03-Modules]
    C --> D[04-State]
    D --> E[05-Best Practices]
    E --> F[06-Advanced]
    F --> G[07-Containers 🆕]
    G --> H[08-Integrations 🆕]
    H --> I[09-Legacy 📌]
```

## 🛠️ Prerequisites

### Required
- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or higher
- Internet connection (for provider downloads)

### Will Be Installed
- Terraform (if not present)
- Supporting tools as needed

### Optional but Recommended
- Docker Desktop
- VS Code
- Git

## 📁 Repository Structure

```
iac_lab/
├── 📄 GETTING_STARTED.md       # Start here for detailed setup
├── 🚀 Start-TerraformLab.ps1   # Interactive lab runner
├── 🔧 Setup-Lab.ps1            # Workspace initialization
├── 📂 01-basics/               # Fundamental concepts
├── 📂 07-containers/           # Modern container tech
├── 📂 08-integrations/         # Tool integrations
├── 📂 09-legacy-optional/      # Legacy technologies
├── 📂 scripts/                 # Supporting automation
│   ├── Check-Environment.ps1
│   ├── Install-LabTools.ps1
│   └── modules/
└── 📂 username-workspace/      # YOUR WORK (git-ignored)
```

## 🎮 Interactive Features

### Real-Time Validation
```powershell
# The lab validates your work automatically
✅ Terraform initialized
✅ Resources created
✅ Outputs configured
🎉 Exercise complete!
```

### Progress Tracking
```powershell
# Track your journey
Progress: 8/20 exercises completed (40%)
[████████████░░░░░░░░░░░░] 40%
```

### Achievement System
- ⭐ First Steps - Complete your first exercise
- ⭐⭐ Infrastructure Builder - Complete 5 exercises
- ⭐⭐⭐ Terraform Practitioner - Complete 10 exercises
- 🌟 Terraform Master - Complete ALL exercises!

### Completion Certificates
Generate beautiful certificates of completion to showcase your achievement!

## 💡 For Windows Admins

This lab bridges your existing knowledge with modern practices:

| Windows/PowerShell | Terraform Equivalent |
|-------------------|---------------------|
| PowerShell DSC | Terraform Configuration |
| `-WhatIf` | `terraform plan` |
| MOF Files | State Files |
| PS Modules | Terraform Providers |
| `Install-Module` | `terraform init` |

## 🤝 Contributing

Found an issue? Have a suggestion? We'd love to hear from you!

1. Open an issue: [GitHub Issues](https://github.com/evilrakir/iac_lab/issues)
2. Submit a PR with improvements
3. Share your success stories!

## 📝 License

This educational lab is provided as-is for learning purposes. Feel free to use, modify, and share!

## 🙏 Acknowledgments

Built with ❤️ for the Windows admin community, bridging traditional IT with modern DevOps practices.

---

**Ready to transform your infrastructure management skills?**

👉 **[Start with GETTING_STARTED.md](GETTING_STARTED.md)** 👈

---

*🔧 PowerShell Native | ☁️ Cloud Ready | 🐋 Container First*