<#
.SYNOPSIS
    Dynamic loader for custom PSScriptAnalyzer rules.

.DESCRIPTION
    This module automatically discovers and loads all custom PSScriptAnalyzer rules 
    co-located in the same directory. It provides a centralized entry point for 
    importing custom rules into PSScriptAnalyzer workflows.

    The module:
    - Dot-sources all *.ps1 rule files in the same directory
    - Discovers functions following the PSCustomRule_* naming convention
    - Exports rules for consumption by PSScriptAnalyzer
    - Provides comprehensive error handling and logging
    - Can be safely re-imported using Import-Module -Force

.PARAMETER Verbose
    Enable verbose output for troubleshooting rule loading and validation.

.EXAMPLE
    Import-Module .\rules\00-PSScriptAnalyzer.Rules.psm1
    
    Loads all custom rules from the rules directory.

.EXAMPLE
    Import-Module .\rules\00-PSScriptAnalyzer.Rules.psm1 -Force -Verbose
    
    Reloads all rules with detailed logging output.

.EXAMPLE
    Invoke-ScriptAnalyzer -Path .\scripts -CustomRulePath .\rules\00-PSScriptAnalyzer.Rules.psm1
    
    Analyzes scripts using the custom rules loaded by this module.

.NOTES
    Module Version: 1.1.0
    Last Modified: 2025-10-21
    
    Requirements:
    - PowerShell 5.1+ or PowerShell Core 7.0+
    - PSScriptAnalyzer module (auto-imported if available)
    
    Location Assumptions:
    - This module must reside in the 'rules' directory
    - Individual rule files (*.ps1) must be in the same directory
    - Rule functions must follow PSCustomRule_* naming convention

.LINK
    https://github.com/Sky-Ledger/powershell-script-analyzer

#>
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

#############################
# MODULE INITIALIZATION
#############################

# Module metadata
$script:ModuleVersion = '1.1.0'
$script:ModuleName = 'SkyLedger.Rules'

# Initialize module paths
$script:ModuleFile = $PSCommandPath
$script:RulesDirectory = Split-Path -Parent $script:ModuleFile

Write-Verbose "Initializing $script:ModuleName module v$script:ModuleVersion"
Write-Verbose "Rules directory: $script:RulesDirectory"

# Validate rules directory exists
if (-not (Test-Path -LiteralPath $script:RulesDirectory)) {
    throw "Rules directory not found: $script:RulesDirectory"
}

#############################
# RULE LOADING LOGIC
#############################

# Get all rule files (exclude this module by name pattern)
$ruleFiles = Get-ChildItem -LiteralPath $script:RulesDirectory -Filter '*.ps1' -File |
    Where-Object { $_.FullName -ne $script:ModuleFile }

Write-Verbose "Found $($ruleFiles.Count) potential rule file(s)"

$loadedRules = @()
$failedRules = @()

# Load each rule file with error handling
foreach ($ruleFile in $ruleFiles) {
    Write-Verbose "Processing rule file: $($ruleFile.Name)"
    
    try {
        # Dot-source the rule file
        . $ruleFile.FullName
        $loadedRules += $ruleFile.Name
        Write-Verbose "Successfully loaded rule file: $($ruleFile.Name)"
    }
    catch {
        Write-Warning "Failed to load rule file '$($ruleFile.Name)': $($_.Exception.Message)"
        $failedRules += $ruleFile.Name
    }
}

#############################
# RULE FUNCTION DISCOVERY
#############################

# Discover PSCustomRule_* functions now present in the session
$ruleFunctions = Get-Command -CommandType Function -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'PSCustomRule_*' } |
    Select-Object -ExpandProperty Name |
    Sort-Object -Unique

Write-Verbose "Discovered $($ruleFunctions.Count) rule function(s): $($ruleFunctions -join ', ')"

#############################
# MODULE EXPORT & SUMMARY
#############################

if ($ruleFunctions.Count -eq 0) {
    Write-Warning "No PSCustomRule_* functions discovered in $script:RulesDirectory"
    Write-Warning "Ensure rule files contain functions with proper PSScriptAnalyzer signatures."
} else {
    Write-Verbose "Exporting $($ruleFunctions.Count) rule function(s)"
    Export-ModuleMember -Function $ruleFunctions
}

# Summary logging
Write-Verbose "Module initialization complete:"
Write-Verbose "  - Rule files processed: $($ruleFiles.Count)"
Write-Verbose "  - Successfully loaded: $($loadedRules.Count)"
Write-Verbose "  - Failed to load: $($failedRules.Count)"
Write-Verbose "  - Rule functions exported: $($ruleFunctions.Count)"

if ($failedRules.Count -gt 0) {
    Write-Warning "Failed to load rule files: $($failedRules -join ', ')"
}