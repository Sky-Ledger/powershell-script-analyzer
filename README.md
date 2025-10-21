# Sky Ledger PowerShell Script Analyzer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![PSScriptAnalyzer](https://img.shields.io/badge/PSScriptAnalyzer-Latest-green.svg)](https://github.com/PowerShell/PSScriptAnalyzer)
[![Pester](https://img.shields.io/badge/Pester-5.0+-orange.svg)](https://pester.dev/)

A comprehensive PowerShell code quality framework with custom rules, automated testing, and GitHub Actions integration.

## 📋 Overview

This repository provides custom PSScriptAnalyzer rules, test automation, and CI/CD integration to ensure consistent PowerShell code quality across Sky Ledger projects. It enforces Sky Ledger coding standards and best practices through automated analysis and testing.

## 🚀 Quick Start

**Prerequisites:** PowerShell 5.1+, PSScriptAnalyzer, Pester v5.0+

```powershell
# Clone and setup
git clone https://github.com/Sky-Ledger/powershell-script-analyzer.git
cd powershell-script-analyzer

# Install modules
Install-Module -Name PSScriptAnalyzer, Pester -Force

# Run analysis
.\Invoke-PSScriptAnalyzer.ps1 -Path ".\rules"

# Run tests
.\tests\Invoke-PesterTests.ps1
```

## 🛠️ Components

## �️ Components

- **`rules/`** - Custom PSScriptAnalyzer rules enforcing Sky Ledger standards
- **`tests/`** - Comprehensive Pester test suite with rule validation
- **`Invoke-PSScriptAnalyzer.ps1`** - Main analyzer script with custom rules
- **`PSScriptAnalyzer.Settings.psd1`** - Configuration for built-in and custom rules
- **`.github/workflows/`** - Automated CI/CD quality checks

## � Usage

```powershell
# Analyze files/directories
.\Invoke-PSScriptAnalyzer.ps1 -Path ".\scripts"
.\Invoke-PSScriptAnalyzer.ps1 -Path ".\MyScript.ps1" -Quiet

# Run tests
.\tests\Invoke-PesterTests.ps1

# Validate environment
.\scripts\Test-WorkflowCompatibility.ps1
```

## 🔧 Configuration

**`PSScriptAnalyzer.Settings.psd1`** configures built-in rules, custom Sky Ledger rules, and severity levels.

**GitHub Actions** automatically run quality checks on pull requests and main branch pushes.

## 💻 Development

**Adding Rules:** Create rule file in `rules/`, add to module, write tests in `tests/`

**Local Testing:** Run `.\scripts\Test-WorkflowCompatibility.ps1` and `.\tests\Invoke-PesterTests.ps1`

**CI/CD:** GitHub Actions automatically validates all changes with full test suite

## ✅ Features

- **Consistent Standards** - Enforces Sky Ledger PowerShell coding practices
- **Automated Testing** - CI/CD integration with comprehensive test coverage
- **Cross-Platform** - Windows PowerShell 5.1+ and PowerShell Core 7.0+
- **Rich Diagnostics** - Color-coded output with detailed error messages

## 🤝 Contributing

1. Fork and create feature branch
2. Follow PowerShell best practices (strict mode, error handling, comment-based help)
3. Add comprehensive Pester tests for new rules
4. Run validation: `.\scripts\Test-WorkflowCompatibility.ps1` and `.\tests\Invoke-PesterTests.ps1`

## 📋 Requirements

- PowerShell 5.1+ or PowerShell Core 7.0+
- PSScriptAnalyzer and Pester modules
- Git

## 🐛 Troubleshooting

**Module Issues:** `Install-Module -Name PSScriptAnalyzer, Pester -Force`

**Test Failures:** `.\tests\Invoke-PesterTests.ps1 -Verbose`

**Help:** `Get-Help .\Invoke-PSScriptAnalyzer.ps1 -Detailed`

## 🎯 Exit Codes

Understanding script exit codes for CI/CD integration:

| Exit Code | Meaning | Action Required |
|-----------|---------|-----------------|
| `0` | Success - No issues found | ✅ Continue pipeline |
| `1` | Analysis issues found | ❌ Fix code quality issues |
| `2` | Invalid path or file type | ❌ Check file paths |
| `3` | PSScriptAnalyzer module missing | ❌ Install required modules |
| `4` | Settings file issues | ❌ Fix configuration |

## 📊 Capabilities

The analyzer supports:

- **Built-in Rules:** Complete set of Microsoft's PSScriptAnalyzer rules
- **Custom Rules:** Sky Ledger specific coding standards and practices  
- **File Types:** `.ps1`, `.psm1`, `.psd1`
- **Cross-Platform:** Windows PowerShell 5.1+ and PowerShell Core 7.0+

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ by the Sky Ledger Team
