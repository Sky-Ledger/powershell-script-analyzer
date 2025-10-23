

---
applyTo: "**/*.ps1"
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
