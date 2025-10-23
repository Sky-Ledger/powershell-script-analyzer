<#
.SYNOPSIS
  Dynamic loader for custom PSScriptAnalyzer rules.

.DESCRIPTION
  Automatically discovers and loads all custom rule *.ps1 files
  co-located in this directory. Provides centralized entry point for importing
  PSCustomRule_* functions into PSScriptAnalyzer workflows.

  Features:
  - Dot-sources all *.ps1 rule files except this module
  - Discovers functions named PSCustomRule_*
  - Exports them for analyzer consumption
  - Safe re-import with -Force

.NOTES
  Module Version: 1.1.1
  Last Modified: 2025-10-23
  Requirements:
    * PowerShell 5.1+ / 7.0+
    * PSScriptAnalyzer installed
  Location Assumptions:
    * This module resides in the 'rules' directory
    * Rule files (*.ps1) in same directory
    * Functions must follow PSCustomRule_* naming convention

.LINK
  https://github.com/Sky-Ledger/powershell-script-analyzer
#>
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Path metadata
$script:ModuleFile = $MyInvocation.MyCommand.Path
$script:RulesDirectory = Split-Path -Parent $script:ModuleFile
Write-Verbose "Rules directory: $script:RulesDirectory"

if (-not (Test-Path -LiteralPath $script:RulesDirectory)) {
  throw "Rules directory not found: $script:RulesDirectory"
}

# Gather rule files
$ruleFiles = Get-ChildItem -LiteralPath $script:RulesDirectory -Filter '*.ps1' -File |
  Where-Object { $_.FullName -ne $script:ModuleFile }
Write-Verbose "Found $($ruleFiles.Count) potential rule file(s)"

$loadedRules = @()
$failedRules = @()
foreach ($ruleFile in $ruleFiles) {
  Write-Verbose "Processing rule file: $($ruleFile.Name)"
  try {
    . $ruleFile.FullName
    $loadedRules += $ruleFile.Name
    Write-Verbose "Successfully loaded rule file: $($ruleFile.Name)"
  }
  catch {
    Write-Warning "Failed to load rule file '$($ruleFile.Name)': $($_.Exception.Message)"
    $failedRules += $ruleFile.Name
  }
}

# Discover rule functions
$ruleFunctions = Get-Command -CommandType Function -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -like 'PSCustomRule_*' } |
  Select-Object -ExpandProperty Name |
  Sort-Object -Unique
Write-Verbose "Discovered $($ruleFunctions.Count) rule function(s): $($ruleFunctions -join ', ')"

if ($ruleFunctions.Count -eq 0) {
  Write-Warning "No PSCustomRule_* functions discovered in $script:RulesDirectory"
  Write-Warning "Ensure rule files contain functions with proper PSScriptAnalyzer signatures."
}
else {
  Write-Verbose "Exporting $($ruleFunctions.Count) rule function(s)"
  Export-ModuleMember -Function $ruleFunctions
}

# Summary
Write-Verbose "Load Summary:"
Write-Verbose "  - Rule files processed: $($ruleFiles.Count)"
Write-Verbose "  - Successfully loaded: $($loadedRules.Count)"
Write-Verbose "  - Failed to load: $($failedRules.Count)"
Write-Verbose "  - Rule functions exported: $($ruleFunctions.Count)"

if ($failedRules.Count -gt 0) {
  Write-Warning "Failed rule files: $($failedRules -join ', ')"
}
