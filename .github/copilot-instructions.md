## 📦 Project Context

- This repository contains custom **PSScriptAnalyzer** rules to enforce PowerShell coding standards.
- It supports **PowerShell 5.1+** and **PowerShell Core 7.0+**.
- Testing is done using **Pester v5+**.
- CI/CD is implemented via **GitHub Actions**, with cross-platform validation.

## 📁 Repository Structure

- `/rules/`: Custom rule scripts (e.g., `PSCustomRule_*` functions)
- `/tests/`: Pester test files for each rule
- `/scripts/`: Utility scripts for local validation
- `/.github/workflows/`: CI pipeline definitions
- `/PSScriptAnalyzer.Settings.psd1`: Analyzer configuration
- `/Invoke-PSScriptAnalyzer.ps1`: Wrapper for running analysis

## 🧪 Testing Requirements

- Each rule must have:
  - Positive and negative test cases
  - Edge case coverage
  - Integration with PSScriptAnalyzer
- Use Arrange-Act-Assert (AAA) pattern in Pester tests.
- Validate compatibility with CI using `Test-WorkflowCompatibility.ps1`.

## 🛠️ Rule Development Guidelines

- Use AST parsing for rule logic.
- Implement token fallback for edge cases.
- Return `DiagnosticRecord` objects for analyzer integration.
- Export rule functions via `00-Custom.Rules.psm1`.
