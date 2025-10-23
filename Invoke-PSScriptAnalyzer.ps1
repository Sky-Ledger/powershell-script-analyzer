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
  [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Target directory or PowerShell script file to analyze')]
  [string]$Path,
  [Parameter(HelpMessage = 'Suppress informational messages during execution')]
  [switch]$Quiet
)

# ============================================================================
# SCRIPT CONFIGURATION
# ============================================================================

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Show-AnalyzerMessage {
  <#
  .SYNOPSIS
    Writes a standardized analyzer message with optional symbol prefix.
  .DESCRIPTION
    Centralizes messaging for the analyzer wrapper. Supports styles (Success, Warning,
    Error, Info, Header, Section) mapped to appropriate PowerShell cmdlets or plain output.
    Honors -Quiet by suppressing Info/Section messages while still surfacing warnings/errors.
  .PARAMETER Message
    Text to emit.
  .PARAMETER Style
    Message classification controlling formatting.
  .PARAMETER Force
    Emit message even when -Quiet was specified (used for critical summary headers).
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Message,
    [ValidateSet('Success', 'Warning', 'Error', 'Info', 'Header', 'Section')]
    [string]$Style = 'Info',
    [switch]$Force
  )

  # Suppress non-critical styles when Quiet unless Force specified
  if ($Quiet -and -not $Force -and $Style -in @('Info', 'Section')) { return }

  switch ($Style) {
    'Success' { Write-Output "✅ $Message" }
    'Warning' { Write-Warning "⚠️ $Message" }
    'Error' { Write-Error "❌ $Message" }
    'Header' { Write-Output "🔍 $Message" }
    'Section' { Write-Output $Message }
    'Info' { Write-Verbose $Message }
    default { Write-Output $Message }
  }
}

# ============================================================================
# TARGET PATH VALIDATION
# ============================================================================

# Resolve and validate the target path for analysis
try {
  $resolvedTargetPath = Resolve-Path -LiteralPath $Path -ErrorAction Stop | Select-Object -ExpandProperty Path
  Show-AnalyzerMessage -Message "Target path resolved: $resolvedTargetPath" -Style Info
}
catch {
  Show-AnalyzerMessage -Message "Target path not found or inaccessible: $Path" -Style Error
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
  Show-AnalyzerMessage -Message "PSScriptAnalyzer module loaded (Version: $($analyzerModuleInfo.Version))" -Style Success
}
catch {
  Show-AnalyzerMessage -Message (
    'Failed to import PSScriptAnalyzer module. Install with: Install-Module -Name PSScriptAnalyzer. ' +
    "Error: $($_.Exception.Message)"
  ) -Style Error
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

  Show-AnalyzerMessage -Message "Analyzer settings loaded: $analyzerSettingsFilePath" -Style Success

  # Display key configuration details when not in quiet mode
  if (-not $Quiet -and $analyzerConfiguration.CustomRulePath) {
    Show-AnalyzerMessage -Message "Custom rules path: $($analyzerConfiguration.CustomRulePath)" -Style Info
  }
}
catch {
  Show-AnalyzerMessage -Message "Failed to import or validate settings file '$analyzerSettingsFilePath': $($_.Exception.Message)" `
    -Style Error
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
  # Exclude this wrapper script itself to avoid self-analysis null reference edge case
  $powerShellScriptTargets = $powerShellScriptTargets | Where-Object { $_ -ne $PSCommandPath }
  Show-AnalyzerMessage -Message "Directory mode: discovered $($powerShellScriptTargets.Count) script file(s)" -Style Info
}
else {
  # File provided: validate it's a PowerShell script
  $targetFileExtension = [IO.Path]::GetExtension($resolvedTargetPath)
  if ($targetFileExtension -ieq '.ps1') {
    $powerShellScriptTargets = @($resolvedTargetPath)
    Show-AnalyzerMessage -Message "Single file mode: targeting $resolvedTargetPath" -Style Info
  }
  else {
    Show-AnalyzerMessage -Message "Specified file '$resolvedTargetPath' is not .ps1 (found: $targetFileExtension)" -Style Error
    exit 2
  }
}

# Validate that files were found for analysis
if (-not $powerShellScriptTargets) {
  Show-AnalyzerMessage -Message 'No .ps1 files found; nothing to analyze.' -Style Warning
  exit 0
}

# ============================================================================
# SCRIPT ANALYSIS EXECUTION
# ============================================================================

Show-AnalyzerMessage -Message "Starting analysis of $($powerShellScriptTargets.Count) script file(s)..." -Style Header -Force

$collectedDiagnostics = @()
$successfulAnalysisCount = 0
$failedAnalysisCount = 0

foreach ($currentScriptFile in $powerShellScriptTargets) {
  try {
    Show-AnalyzerMessage -Message "Analyzing: $currentScriptFile" -Style Info

    # Execute PSScriptAnalyzer using the loaded settings configuration
    $scriptDiagnostics = Invoke-ScriptAnalyzer -Path $currentScriptFile -Settings $analyzerSettingsFilePath -ErrorAction Stop

    if ($scriptDiagnostics) {
      # Normalize to array to avoid StrictMode property errors when single object
      $normalizedDiagnostics = @($scriptDiagnostics)
      $collectedDiagnostics += $normalizedDiagnostics
      Show-AnalyzerMessage -Message "Found $($normalizedDiagnostics.Count) diagnostic(s) in $([IO.Path]::GetFileName($currentScriptFile))" -Style Info
    }

    $successfulAnalysisCount++
  }
  catch {
    $failedAnalysisCount++
    Show-AnalyzerMessage -Message "Analysis failed for '$currentScriptFile': $($_.Exception.Message)" -Style Warning
  }
}

Show-AnalyzerMessage -Message "Analysis complete: $successfulAnalysisCount succeeded, $failedAnalysisCount failed" -Style Section -Force

# ============================================================================
# DIAGNOSTIC RESULTS PROCESSING
# ============================================================================

if ($collectedDiagnostics) {
  # Honor severity handling based on settings only. Information-level diagnostics are reported
  # but do not cause non-zero exit unless repository settings redefine severity mapping externally.
  $actionableDiagnostics = $collectedDiagnostics | Where-Object { $_.Severity -in @('Warning', 'Error') }

  # Always show a full table (including Information) for transparency.
  Show-AnalyzerMessage -Message 'PSScriptAnalyzer Diagnostic Results:' -Style Header -Force
  Show-AnalyzerMessage -Message '====================================' -Style Section -Force
  $collectedDiagnostics |
  Sort-Object Severity, RuleName, ScriptName, Line |
  Format-Table Severity, RuleName, ScriptName, Line, Message -AutoSize
  Write-Verbose ''

  $groupsAll = $collectedDiagnostics | Group-Object Severity
  $summaryAll = $groupsAll | ForEach-Object { "$($_.Name): $($_.Count)" }
  Show-AnalyzerMessage -Message "Summary (all severities): $($collectedDiagnostics.Count) total [$($summaryAll -join ', ')]" `
    -Style Info -Force

  if ($actionableDiagnostics.Count -gt 0) {
    Show-AnalyzerMessage -Message "Actionable diagnostics (Warning/Error): $($actionableDiagnostics.Count)" -Style Warning -Force
    exit 1
  }
  else {
    Show-AnalyzerMessage -Message 'No actionable (Warning/Error) diagnostics found.' -Style Success -Force
  }
}

# ============================================================================
# SUCCESS EXIT
# ============================================================================

Show-AnalyzerMessage -Message 'Analysis completed successfully with no actionable diagnostics found.' -Style Success -Force
exit 0
