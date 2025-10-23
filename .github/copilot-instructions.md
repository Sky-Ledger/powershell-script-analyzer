## 📦 Project Context

- This repository contains custom **PSScriptAnalyzer** rules to enforce PowerShell coding standards.
- It supports **PowerShell 5.1+** and **PowerShell Core 7.0+**.
- Testing is done using **Pester v5+**.
- CI/CD is implemented via **GitHub Actions**, with cross-platform validation.

---

## 📁 Repository Structure

- `/rules/`: Custom rule scripts (e.g., `PSCustomRule_*` functions)
- `/tests/`: Pester test files for each rule
- `/scripts/`: Utility scripts for local validation
- `/.github/workflows/`: CI pipeline definitions
- `/PSScriptAnalyzer.Settings.psd1`: Analyzer configuration
- `/Invoke-PSScriptAnalyzer.ps1`: Wrapper for running analysis

---

## 🧩 Coding Standards

### PowerShell Practices

- Use `Set-StrictMode -Version 3.0` at the start of every script.
- Set `$ErrorActionPreference = 'Stop'` globally.
- Use `[CmdletBinding()]` and `[Parameter()]` attributes for all functions.
- Include comment-based help: `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`.
- Separate functions and logic in powershell in sections:
  - keep function definitions at the top of the script
- Prefer `Write-Verbose`, `Write-Warning`, `Write-Error` or `Write-Output`over `Write-Host`.
- Consolidate `Write-` commands in a function starting with `Show-` to standardize output formatting.

### Naming Conventions

- Custom rules must be named `PSCustomRule_<RuleName>`.
- Use PascalCase for function names.
- Use `[Verb-Noun]` naming per PowerShell standards.

---

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

---

## ✅ Summary of Key Rules

- Always use strict mode and stop-on-error.
- Name rules as `PSCustomRule_*`.
- Include full comment-based help.
- Write Pester tests for every rule.
- Use AST parsing, not regex.
