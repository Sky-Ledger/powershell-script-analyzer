<#
.SYNOPSIS
    Executes PSScriptAnalyzer with custom Sky-Ledger rules and repository-specific settings.

.DESCRIPTION
    This script provides a standardized wrapper for running PSScriptAnalyzer against PowerShell
    scripts using the Sky-Ledger custom rules and configuration. It ensures consistent code
    quality validation across the repository by enforcing the settings defined in 
    PSScriptAnalyzer.Settings.psd1.

    Key Features:
    - Loads custom analyzer rules and settings from PSScriptAnalyzer.Settings.psd1
    - Recursively analyzes all .ps1 files in directories or individual script files
    - Provides formatted diagnostic output with severity-based filtering
    - Returns appropriate exit codes for CI/CD pipeline integration
    - Supports quiet mode for automated builds and verbose information inclusion

.PARAMETER Path
    Specifies the target directory or PowerShell script file to analyze.
    When a directory is provided, all .ps1 files are recursively analyzed.
    When a file is provided, only that specific .ps1 file is analyzed.
    This parameter is mandatory.

.PARAMETER Quiet
    Suppresses informational messages during execution, displaying only diagnostic results.
    Useful for automated builds and CI/CD pipelines where minimal output is desired.

.PARAMETER IncludeInfo
    Includes Information-level diagnostics in both output display and exit code determination.
    By default, only Warning and Error level diagnostics affect the exit code.
    When this switch is used, Information-level diagnostics will also cause a non-zero exit code.

.EXAMPLE
    .\Invoke-PSScriptAnalyzer.ps1 -Path ".\rules"
    
    Analyzes all PowerShell scripts in the rules directory and subdirectories,
    displaying informational messages and diagnostic results.

.EXAMPLE
    .\Invoke-PSScriptAnalyzer.ps1 -Path ".\MyScript.ps1" -Quiet
    
    Analyzes the specific MyScript.ps1 file in quiet mode, suppressing
    informational messages and showing only diagnostic results.

.EXAMPLE
    .\Invoke-PSScriptAnalyzer.ps1 -Path "." -IncludeInfo -Quiet
    
    Analyzes all PowerShell scripts in the current directory, including
    Information-level diagnostics in results and exit code determination,
    while running in quiet mode.

.NOTES
    Author: Sky-Ledger Team
    Version: 1.1.0
    
    Requirements:
    - PSScriptAnalyzer module must be installed
    - PSScriptAnalyzer.Settings.psd1 must exist in the script directory
    - Custom rules module must be accessible via settings configuration

    Exit Codes:
    0 = Analysis successful, no actionable diagnostics found
    1 = Diagnostics found (Warnings/Errors, or Information when -IncludeInfo used)
    2 = Target path not found or invalid file type
    3 = Failed to import PSScriptAnalyzer module
    4 = Settings file not found or invalid configuration

.LINK
    https://github.com/PowerShell/PSScriptAnalyzer
    
.LINK
    https://docs.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Target directory or PowerShell script file to analyze")]
    [string]$Path,
    
    [Parameter(HelpMessage = "Suppress informational messages during execution")]
    [switch]$Quiet,
    
    [Parameter(HelpMessage = "Include Information-level diagnostics in output and exit code determination")]
    [switch]$IncludeInfo
)

# ============================================================================
# SCRIPT CONFIGURATION
# ============================================================================

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
    Writes informational messages when not in quiet mode.

.DESCRIPTION
    Provides conditional output of informational messages based on the Quiet parameter.
    Messages are displayed in cyan color to distinguish from diagnostic output.

.PARAMETER InformationMessage
    The message to display when not in quiet mode.
#>
function Write-InformationalMessage {
    param([string]$InformationMessage)
    
    if (-not $Quiet) {
        Write-Host $InformationMessage -ForegroundColor Cyan
    }
}

# ============================================================================
# TARGET PATH VALIDATION
# ============================================================================

# Resolve and validate the target path for analysis
try {
    $resolvedTargetPath = Resolve-Path -LiteralPath $Path -ErrorAction Stop | Select-Object -ExpandProperty Path
    Write-InformationalMessage "Target path resolved: $resolvedTargetPath"
} catch {
    Write-Error "Target path not found or inaccessible: $Path"
    exit 2
}

# ============================================================================
# PSSCRIPTANALYZER MODULE VALIDATION
# ============================================================================

# Ensure PSScriptAnalyzer module is available (prerequisite for analysis)
# Note: No auto-installation to maintain deterministic behavior in CI/CD environments
try {
    Import-Module PSScriptAnalyzer -ErrorAction Stop | Out-Null
    $analyzerModuleInfo = Get-Module PSScriptAnalyzer
    Write-InformationalMessage "PSScriptAnalyzer module loaded successfully (Version: $($analyzerModuleInfo.Version))"
} catch {
    Write-Error "Failed to import PSScriptAnalyzer module. Please install using: Install-Module -Name PSScriptAnalyzer. Error: $($_.Exception.Message)"
    exit 3
}

# ============================================================================
# ANALYZER SETTINGS CONFIGURATION
# ============================================================================

# Locate and load PSScriptAnalyzer configuration file
$scriptDirectoryPath = Split-Path -Parent $PSCommandPath
$analyzerSettingsFilePath = Join-Path $scriptDirectoryPath 'PSScriptAnalyzer.Settings.psd1'

# Validate settings file existence
if (-not (Test-Path -LiteralPath $analyzerSettingsFilePath)) {
    Write-Error "PSScriptAnalyzer settings file not found: $analyzerSettingsFilePath"
    exit 4
}

# Import and validate settings configuration
try {
    $analyzerConfiguration = Import-PowerShellDataFile -LiteralPath $analyzerSettingsFilePath
    if (-not $analyzerConfiguration) {
        throw 'Settings file import returned null or empty configuration'
    }
    
    Write-InformationalMessage "Analyzer settings loaded successfully: $analyzerSettingsFilePath"
    
    # Display key configuration details when not in quiet mode
    if (-not $Quiet -and $analyzerConfiguration.CustomRulePath) {
        Write-InformationalMessage "Custom rules path: $($analyzerConfiguration.CustomRulePath)"
    }
} catch {
    Write-Error "Failed to import or validate settings file '$analyzerSettingsFilePath': $($_.Exception.Message)"
    exit 4
}

# ============================================================================
# TARGET FILE DISCOVERY
# ============================================================================

# Discover PowerShell script files for analysis
$powerShellScriptTargets = @()

if (Test-Path -LiteralPath $resolvedTargetPath -PathType Container) {
    # Directory provided: recursively find all .ps1 files
    $discoveredScriptFiles = Get-ChildItem -LiteralPath $resolvedTargetPath -Recurse -Include *.ps1 -File
    $powerShellScriptTargets = $discoveredScriptFiles | Select-Object -ExpandProperty FullName
    Write-InformationalMessage "Directory analysis mode: discovered $($powerShellScriptTargets.Count) PowerShell script file(s)"
} else {
    # File provided: validate it's a PowerShell script
    $targetFileExtension = [IO.Path]::GetExtension($resolvedTargetPath)
    if ($targetFileExtension -ieq '.ps1') {
        $powerShellScriptTargets = @($resolvedTargetPath)
        Write-InformationalMessage "Single file analysis mode: targeting $resolvedTargetPath"
    } else {
        Write-Error "Specified file '$resolvedTargetPath' is not a PowerShell script (.ps1). Found extension: $targetFileExtension"
        exit 2
    }
}

# Validate that files were found for analysis
if (-not $powerShellScriptTargets) {
    Write-InformationalMessage 'No PowerShell script files (.ps1) found in the specified path. Analysis complete with no targets.'
    exit 0
}

# ============================================================================
# SCRIPT ANALYSIS EXECUTION
# ============================================================================

Write-InformationalMessage "Starting analysis of $($powerShellScriptTargets.Count) PowerShell script file(s)..."

$collectedDiagnostics = @()
$successfulAnalysisCount = 0
$failedAnalysisCount = 0

foreach ($currentScriptFile in $powerShellScriptTargets) {
    try {
        Write-InformationalMessage "Analyzing: $currentScriptFile"
        
        # Execute PSScriptAnalyzer using the loaded settings configuration
        $scriptDiagnostics = Invoke-ScriptAnalyzer -Path $currentScriptFile -Settings $analyzerSettingsFilePath -ErrorAction Stop
        
        if ($scriptDiagnostics) {
            $collectedDiagnostics += $scriptDiagnostics
            Write-InformationalMessage "  Found $($scriptDiagnostics.Count) diagnostic(s) in $([IO.Path]::GetFileName($currentScriptFile))"
        }
        
        $successfulAnalysisCount++
    } catch {
        $failedAnalysisCount++
        Write-Warning "Analysis failed for '$currentScriptFile': $($_.Exception.Message)"
    }
}

Write-InformationalMessage "Analysis complete: $successfulAnalysisCount successful, $failedAnalysisCount failed"

# ============================================================================
# DIAGNOSTIC RESULTS PROCESSING
# ============================================================================

if ($collectedDiagnostics) {
    # Apply severity filtering based on IncludeInfo parameter
    $filteredDiagnostics = if ($IncludeInfo) {
        # Include all diagnostics when IncludeInfo is specified
        $collectedDiagnostics
    } else {
        # Exclude Information-level diagnostics by default
        $collectedDiagnostics | Where-Object { $_.Severity -ne 'Information' }
    }
    
    if ($filteredDiagnostics) {
        # Display diagnostic results in formatted table
        Write-Host ''
        Write-Host "PSScriptAnalyzer Diagnostic Results:" -ForegroundColor Yellow
        Write-Host "====================================" -ForegroundColor Yellow
        
        $sortedDiagnostics = $filteredDiagnostics | Sort-Object Severity, RuleName, ScriptName, Line
        $sortedDiagnostics | Format-Table Severity, RuleName, ScriptName, Line, Message -AutoSize
        
        Write-Host ''
        
        # Display summary with severity breakdown
        $severityGroups = $filteredDiagnostics | Group-Object Severity
        $severitySummary = $severityGroups | ForEach-Object { "$($_.Name): $($_.Count)" }
        Write-Host "Diagnostic Summary: $($filteredDiagnostics.Count) total [$($severitySummary -join ', ')] (IncludeInfo: $IncludeInfo)" -ForegroundColor Yellow
        
        exit 1
    } else {
        Write-InformationalMessage "All diagnostics were Information-level and excluded due to IncludeInfo parameter setting."
    }
}

# ============================================================================
# SUCCESS EXIT
# ============================================================================

Write-InformationalMessage 'Analysis completed successfully with no actionable diagnostics found.'
exit 0
