# Sky Ledger PowerShell Script Analyzer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![PSScriptAnalyzer](https://img.shields.io/badge/PSScriptAnalyzer-1.20%2B-green.svg)](https://github.com/PowerShell/PSScriptAnalyzer)
[![Pester](https://img.shields.io/badge/Pester-5.0%2B-orange.svg)](https://pester.dev/)

A comprehensive PowerShell code quality framework with custom rules, automated testing, and GitHub Actions integration.

## 📋 Overview

This repository provides custom PSScriptAnalyzer rules, test automation, and CI/CD integration to ensure consistent PowerShell code quality across Sky Ledger projects. It enforces Sky Ledger coding standards and best practices through automated analysis and testing.

## 🚀 Quick Start

### Prerequisites

- **PowerShell 5.1+** or **PowerShell Core 7.0+**
- **PSScriptAnalyzer 1.20+** - `Install-Module -Name PSScriptAnalyzer`
- **Pester 5.0+** - `Install-Module -Name Pester -MinimumVersion 5.0.0`
- **Git** - Must be available in your system PATH

### Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Sky-Ledger/powershell-script-analyzer.git
   cd powershell-script-analyzer
   ```

2. **Validate your environment:**

   ```powershell
   .\scripts\Test-WorkflowCompatibility.ps1
   ```

3. **Run code analysis:**

   ```powershell
   .\Invoke-PSScriptAnalyzer.ps1 -Path ".\rules"
   ```

4. **Execute tests:**

   ```powershell
   .\tests\Invoke-PesterTests.ps1
   ```

## 🛠️ Components

### 📁 Repository Structure

```plaintext
powershell-script-analyzer/
├── .github/                               # GitHub Actions configuration
│   └── workflows/
│       └── powershell-quality-check.yml
├── rules/                                 # Custom PSScriptAnalyzer rules
│   ├── 00-SkyLedger.Rules.psm1            # Main rules module
│   ├── ErrorActionPreferenceStop.ps1      # $ErrorActionPreference rule
│   └── StrictModeVersion.ps1              # Set-StrictMode rule
├── tests/                                 # Pester test suite
│   ├── ErrorActionPreferenceStop/         # Rule-specific tests
│   ├── StrictModeVersion/                 # Rule-specific tests
│   └── Invoke-PesterTests.ps1             # Test runner
├── scripts/                               # Utility scripts
│   └── Test-WorkflowCompatibility.ps1     # Environment validation
├── Invoke-PSScriptAnalyzer.ps1            # Main analyzer script
├── PSScriptAnalyzer.Settings.psd1         # Analyzer configuration
├── LICENSE                                # MIT License
└── README.md                              # This file
```

### 🔍 Custom Rules

#### 1. **ErrorActionPreferenceStop Rule**

- **Purpose:** Ensures all PowerShell scripts include `$ErrorActionPreference = 'Stop'`
- **Rationale:** Promotes fail-fast behavior and consistent error handling
- **Severity:** Warning
- **Auto-fix:** Not available

#### 2. **StrictModeVersion Rule**

- **Purpose:** Enforces `Set-StrictMode -Version 3.0` in all PowerShell scripts
- **Rationale:** Enables strict variable checking and modern PowerShell practices
- **Severity:** Warning
- **Auto-fix:** Not available

### 🧪 Testing Framework

**Comprehensive test coverage for all custom rules:**

- ✅ **Positive Tests** - Verify rules trigger correctly for violations
- ✅ **Negative Tests** - Ensure rules don't trigger false positives  
- ✅ **Edge Cases** - Test boundary conditions and special scenarios
- ✅ **Module Loading** - Validate rule module functionality
- ✅ **Integration** - Test complete analysis workflow

## 🚀 Usage Examples

### Basic Code Analysis

```powershell
# Analyze a single PowerShell file
.\Invoke-PSScriptAnalyzer.ps1 -Path ".\MyScript.ps1"

# Analyze all PowerShell files in a directory
.\Invoke-PSScriptAnalyzer.ps1 -Path ".\scripts"

# Run analysis in quiet mode (minimal output)
.\Invoke-PSScriptAnalyzer.ps1 -Path ".\rules" -Quiet

# Include Information-level diagnostics
.\Invoke-PSScriptAnalyzer.ps1 -Path ".\rules" -IncludeInfo
```

### Test Execution

```powershell
# Run all tests with detailed output
.\tests\Invoke-PesterTests.ps1

# Run tests in quiet mode
.\tests\Invoke-PesterTests.ps1 -Quiet

# Run tests with verbose module loading
.\tests\Invoke-PesterTests.ps1 -Verbose
```

### Environment Validation

```powershell
# Validate GitHub workflow compatibility
.\scripts\Test-WorkflowCompatibility.ps1

# Check requirements for CI/CD integration
Get-Help .\scripts\Test-WorkflowCompatibility.ps1 -Detailed
```

## 🔧 Configuration

### PSScriptAnalyzer Settings

The `PSScriptAnalyzer.Settings.psd1` file controls analysis behavior:

```powershell
@{
    # Include built-in and custom rules
    IncludeRules = @(
        'PSAvoidDefaultValueSwitchParameter',
        'PSAvoidGlobalVars',
        # ... 70+ additional rules
        '00-SkyLedger.Rules\*'
    )
    
    # Path to custom rules module
    CustomRulePath = '.\rules\00-SkyLedger.Rules.psm1'
    
    # Analysis severity levels
    Severity = @('Warning', 'Error', 'Information')
}
```

### GitHub Actions Integration

Automated quality checks run on:

- **Pull Requests** - Validate code changes
- **Push to Main** - Ensure main branch quality
- **Manual Dispatch** - On-demand analysis

## 💻 Development Workflow

### 1. **Local Development**

```powershell
# Validate environment setup
.\scripts\Test-WorkflowCompatibility.ps1

# Analyze your PowerShell code
.\Invoke-PSScriptAnalyzer.ps1 -Path ".\your-scripts"

# Run tests to ensure rules work correctly
.\tests\Invoke-PesterTests.ps1
```

### 2. **Adding New Rules**

```powershell
# Create new rule file in .\rules\
# Add rule to 00-SkyLedger.Rules.psm1
# Create comprehensive tests in .\tests\
# Update PSScriptAnalyzer.Settings.psd1 if needed
```

### 3. **Continuous Integration**

The GitHub workflow automatically:

- Installs required PowerShell modules
- Runs PSScriptAnalyzer with custom rules
- Executes full Pester test suite
- Reports results and blocks merges on failures

## 📊 Features & Benefits

### ✅ **Code Quality Assurance**

- **Consistent Standards** - Enforces Sky Ledger PowerShell coding practices
- **Early Detection** - Catches issues before code review and deployment
- **Automated Enforcement** - Integrates with GitHub Actions for automatic validation
- **Comprehensive Coverage** - 70+ built-in rules plus custom Sky Ledger rules

### 🛡️ **Reliability & Testing**

- **Extensive Test Suite** - 13 comprehensive tests covering all rule scenarios
- **CI/CD Integration** - Automated testing on every code change
- **Cross-Platform Support** - Works on Windows PowerShell 5.1+ and PowerShell Core 7.0+
- **Professional Documentation** - Complete comment-based help system

### 📈 **Developer Experience**

- **Rich Output** - Color-coded analysis results and progress indicators
- **Flexible Configuration** - Customizable rules and severity levels  
- **Detailed Diagnostics** - Clear error messages with line numbers and remediation guidance
- **Help Integration** - Full `Get-Help` support with examples and troubleshooting

### 🚀 **Automation Benefits**

- **Environment Validation** - Pre-flight checks ensure proper setup
- **Batch Processing** - Analyze entire directories recursively
- **Exit Code Integration** - Perfect for CI/CD pipeline integration
- **Quiet Mode Support** - Minimal output for automated builds

## 🤝 Contributing

### Development Guidelines

1. **Fork** the repository and create a feature branch
2. **Follow PowerShell Best Practices:**
   - Include `Set-StrictMode -Version 3.0`
   - Add `$ErrorActionPreference = 'Stop'`
   - Use comment-based help for all functions
   - Follow consistent naming conventions

3. **Testing Requirements:**
   - Add comprehensive Pester tests for new rules
   - Test positive cases (rule should trigger)
   - Test negative cases (rule should not trigger)
   - Test edge cases and boundary conditions

4. **Documentation:**
   - Update README.md for new features
   - Add inline comments explaining rule logic
   - Include usage examples in help documentation

### Code Review Process

```powershell
# Before submitting PR:
# 1. Run environment validation
.\scripts\Test-WorkflowCompatibility.ps1

# 2. Analyze your changes
.\Invoke-PSScriptAnalyzer.ps1 -Path ".\rules"

# 3. Run full test suite
.\tests\Invoke-PesterTests.ps1

# 4. Ensure all tests pass ✅
```

## 📋 Requirements

### System Requirements

- **Operating System:** Windows 10+, macOS 10.15+, or Linux (Ubuntu 18.04+)
- **PowerShell:** 5.1+ (Windows) or 7.0+ (Cross-platform)
- **Git:** Any recent version available in PATH

### PowerShell Module Requirements

```powershell
# Required modules (install automatically in CI/CD)
Install-Module -Name PSScriptAnalyzer -MinimumVersion 1.20.0
Install-Module -Name Pester -MinimumVersion 5.0.0 -Force
```

### Development Environment

- **VS Code** with PowerShell extension (recommended)
- **PowerShell ISE** (Windows PowerShell 5.1)
- **Any text editor** with PowerShell syntax support

## 🐛 Troubleshooting

### Common Issues

#### Module Import Failures

```powershell
# Solution: Install required modules
Install-Module -Name PSScriptAnalyzer -Force
Install-Module -Name Pester -MinimumVersion 5.0.0 -Force

# Validate installation
.\scripts\Test-WorkflowCompatibility.ps1
```

#### Test Failures

```powershell
# Run tests with verbose output for debugging
.\tests\Invoke-PesterTests.ps1 -Verbose

# Check individual test files
Invoke-Pester .\tests\ErrorActionPreferenceStop\Missing.Tests.ps1 -Verbose
```

#### Custom Rules Not Loading

```powershell
# Verify module path in settings
Get-Content .\PSScriptAnalyzer.Settings.psd1

# Test manual module import
Import-Module .\rules\00-SkyLedger.Rules.psm1 -Force -Verbose
Get-Command -Module "00-SkyLedger.Rules"
```

### Getting Help

- **Script Help:** `Get-Help .\Invoke-PSScriptAnalyzer.ps1 -Detailed`
- **Test Help:** `Get-Help .\tests\Invoke-PesterTests.ps1 -Examples`
- **Environment Check:** `.\scripts\Test-WorkflowCompatibility.ps1`
- **Rule Documentation:** Inline comments in rule files

### Performance Optimization

```powershell
# For large codebases, use targeted analysis
.\Invoke-PSScriptAnalyzer.ps1 -Path ".\specific-folder" -Quiet

# Parallel execution for multiple files (advanced users)
# Consider using PowerShell workflow or foreach -parallel
```

## 🎯 Exit Codes

Understanding script exit codes for CI/CD integration:

| Exit Code | Meaning | Action Required |
|-----------|---------|-----------------|
| `0` | Success - No issues found | ✅ Continue pipeline |
| `1` | Analysis issues found | ❌ Fix code quality issues |
| `2` | Invalid path or file type | ❌ Check file paths |
| `3` | PSScriptAnalyzer module missing | ❌ Install required modules |
| `4` | Settings file issues | ❌ Fix configuration |

## 📊 Rule Statistics

Current rule coverage:

- **Built-in Rules:** 72 PSScriptAnalyzer rules
- **Custom Rules:** 2 Sky Ledger specific rules  
- **Test Coverage:** 13 comprehensive test scenarios
- **Supported File Types:** `.ps1`, `.psm1`, `.psd1`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Made with ❤️ by the Sky Ledger Team
