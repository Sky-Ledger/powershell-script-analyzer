# PowerShell Quality Check Workflow

This GitHub Actions workflow (`powershell-quality-check.yml`) enforces PowerShell code quality and test coverage on every push and pull request to `main` and `develop` affecting scripts, modules, analyzer settings, rules, or tests.

## What It Does

1. Installs required modules: PSScriptAnalyzer and Pester (v5+).
2. Imports custom analyzer rules from `rules/00-PSScriptAnalyzer.Rules.psm1`.
3. Verifies each custom rule has corresponding tests under `tests/<RuleName>/`.
4. Runs all Pester tests via `tests/Invoke-PesterTests.ps1`.
5. Executes repository-wide static analysis with `Invoke-PSScriptAnalyzer.ps1` using `PSScriptAnalyzer.Settings.psd1`.
6. Provides a summary and runs a Windows PowerShell 5.1 compatibility pass (syntax check) on a separate job.

## Exit Behavior

- Pester failures or analyzer warnings/errors cause a non-zero job exit.
- All diagnostics must be resolved before merging.

## When It Runs

- On push/pull request to `main` or `develop` (scoped to PowerShell-related paths).
- Manually via `workflow_dispatch`.

## Why It Matters

Ensures consistent style, validated custom rules, test coverage, cross-platform compatibility (PowerShell 7 + Windows PowerShell 5.1), and prevents regression in analyzer configuration.

## Quick Fix Tips

- Missing rule tests: add `*.Tests.ps1` in `tests/<RuleName>/`.
- Analyzer issues: run `./Invoke-PSScriptAnalyzer.ps1 -Path .` locally.
- Module problems: reinstall with `Install-Module PSScriptAnalyzer, Pester`.

Keep scripts clean, small, and under the configured line length; eliminate trailing whitespace before committing.
