<#
.SYNOPSIS
  Comprehensive test runner for Sky-Ledger PowerShell Script Analyzer custom rules validation.

.DESCRIPTION
  This script serves as the primary entry point for executing all Pester v5-based tests for the
  custom PSScriptAnalyzer rules. It handles prerequisites, module loading, test discovery, and
  result reporting suitable for both local development and CI/CD pipelines.

  Key Responsibilities:
  - Validates Pester v5+ availability and imports required testing framework
  - Dynamically loads custom PSScriptAnalyzer rules module (00-Custom.Rules.psm1)
  - Discovers and executes all test files (*.Tests.ps1) in specified directory structure
  - Provides configurable output verbosity for different execution contexts
  - Returns standardized exit codes for automated build process integration

.PARAMETER TestRootPath
  Specifies the root directory containing test files. Defaults to '../tests' relative to script location.
  All *.Tests.ps1 files in this directory and subdirectories will be discovered and executed.

.PARAMETER Quiet
  Enables minimal output mode for CI/CD scenarios. When specified, reduces Pester output verbosity
  to essential information only (test counts, duration, pass/fail status).

.EXAMPLE
  .\Invoke-PesterTests.ps1
    Runs all tests with default settings - discovers tests in ../tests directory with detailed output.

.EXAMPLE
  .\Invoke-PesterTests.ps1 -Quiet
    Runs all tests with minimal output suitable for CI/CD pipelines.

.EXAMPLE
  .\Invoke-PesterTests.ps1 -TestRootPath "C:\CustomTests"
    Runs tests from a custom directory location with detailed output.

.NOTES
  Exit Codes:
  0 = Success - All tests passed successfully
  1 = Test Failure - One or more tests failed execution
  2 = Configuration Error - Test root path not found or inaccessible
  3 = Module Error - Failed to import custom analyzer rules module
  4 = Framework Error - No test summary returned by Pester (unexpected condition)
  5 = Prerequisite Error - Pester v5+ not available and cannot proceed

  Prerequisites:
  - PowerShell 5.1+ or PowerShell Core 7.0+
  - Pester v5.0.0 or higher (must be pre-installed)
  - Custom rules module (00-Custom.Rules.psm1) must exist in ../rules directory

.LINK
  https://github.com/Sky-Ledger/powershell-script-analyzer
#>
param(
  # Use explicit named parameters for Join-Path to avoid positional parameter analyzer warnings
  [string] $TestRootPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'tests'),
  [switch] $Quiet
)

# Enable strict mode and stop on errors for robust execution
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

#############################
# PREREQUISITE VALIDATION
#############################

<#
.SYNOPSIS
  Validates that Pester v5+ is available and imports the testing framework.

.DESCRIPTION
  Checks for Pester module availability with minimum version requirements.
  Does not auto-install to avoid unexpected modifications to the environment.
  Provides clear error messages with installation instructions if prerequisites are not met.
#>
function Test-PesterModulePrerequisite {
  $minimumPesterVersion = [Version]'5.0.0'

  # Find the latest available Pester module version (pipeline continuation indented two spaces per settings)
  $latestAvailablePester = Get-Module -ListAvailable -Name Pester |
  Sort-Object -Property Version -Descending |
  Select-Object -First 1

  # Validate version requirements
  if (-not $latestAvailablePester -or $latestAvailablePester.Version -lt $minimumPesterVersion) {
    $installInstruction = 'Install-Module Pester -Scope CurrentUser -MinimumVersion {0}' -f $minimumPesterVersion
    Write-Error "Pester v5+ is required but not installed. Please run: $installInstruction"
    exit 5
  }

  # Import Pester with version constraint
  Write-Verbose "Loading Pester v$($latestAvailablePester.Version)"
  Import-Module Pester -MinimumVersion $minimumPesterVersion -ErrorAction Stop
}

<#
.SYNOPSIS
  Imports the custom PSScriptAnalyzer rules module required for testing.

.DESCRIPTION
  Locates and imports the custom rules module (00-Custom.Rules.psm1).
  This module contains the PSCustomRule_* functions that are being validated by the test suite.
  Uses -Force to ensure fresh import and avoid module caching issues during development.
#>
function Import-CustomAnalyzerRulesModule {
  # Resolve the repository root directory from script location
  $repositoryRootPath = (Join-Path $PSScriptRoot '..') |
  Resolve-Path -ErrorAction Stop |
  Select-Object -ExpandProperty Path

  # Construct path to the custom rules module
  $customRulesModulePath = Join-Path $repositoryRootPath 'rules/00-Custom.Rules.psm1'

  # Validate module existence before attempting import
  if (-not (Test-Path -LiteralPath $customRulesModulePath)) {
    Write-Error "Custom analyzer rules module not found at expected location: $customRulesModulePath"
    exit 3
  }

  # Import module with force to ensure fresh loading
  Write-Information "Importing custom analyzer rules module: $customRulesModulePath"
  Import-Module $customRulesModulePath -Force -ErrorAction Stop

  Write-Verbose 'Successfully loaded custom PSScriptAnalyzer rules module'
}

#############################
# INITIALIZATION
#############################

# Validate and import required testing framework
Test-PesterModulePrerequisite

# Load custom PSScriptAnalyzer rules module that contains the functions being tested
Import-CustomAnalyzerRulesModule

#############################
# TEST DISCOVERY & VALIDATION
#############################

# Verify that the specified test directory exists and is accessible
if (-not (Test-Path -LiteralPath $TestRootPath)) {
  Write-Error "Test root path not found or inaccessible: $TestRootPath"
  exit 2
}

# Configure Pester output verbosity based on execution context
$pesterOutputVerbosityLevel = if ($Quiet) { 'Minimal' } else { 'Detailed' }

#############################
# TEST EXECUTION
#############################

Write-Information "Discovering Pester tests in: $TestRootPath"
Write-Verbose "Using output verbosity level: $pesterOutputVerbosityLevel"

# Execute all discovered tests with PassThru to capture results for analysis
$testExecutionResults = Invoke-Pester -Path $TestRootPath -Output $pesterOutputVerbosityLevel -PassThru

#############################
# RESULTS ANALYSIS & REPORTING
#############################

# Validate that Pester returned test execution results
if (-not $testExecutionResults) {
  Write-Error 'No test execution summary returned by Pester framework - this indicates an unexpected condition.'
  exit 4
}

# Extract test execution statistics for reporting and exit code determination
# Pester v5 PassThru object exposes *Count properties (integers). Fallback to collections if present.
if ($null -eq $testExecutionResults) {
  Write-Error 'Pester returned no results object.'
  exit 4
}

<#
.SYNOPSIS
  Safely retrieves a test result count from a Pester PassThru object.

.DESCRIPTION
  Pester v5 PassThru objects may present either discrete *Count integer properties
  (e.g. PassedCount, FailedCount, SkippedCount) or expose collections (Passed, Failed, Skipped).
  This helper normalizes access by checking for the count property first, then
  falling back to counting the collection if present, returning 0 when neither exists.

.PARAMETER Result
  The PassThru results object returned by Invoke-Pester -PassThru.

.PARAMETER Name
  Base name of the result group (Passed | Failed | Skipped) without the 'Count' suffix.

.OUTPUTS
  [int] The numeric count of the requested result group.

.EXAMPLE
  Get-TestResultCount -Result $r -Name 'Passed'
  Returns number of passed tests regardless of PassThru shape.

.EXAMPLE
  $failed = Get-TestResultCount -Result $r -Name 'Failed'
  Uses FailedCount if available, else counts $r.Failed.

.NOTES
  Ensures resilience across minor Pester schema differences and supports analyzer
  rule PSAvoidLongLines by encapsulating logic.
#>
function Get-TestResultCount {
  [CmdletBinding()]
  [OutputType([int])]
  param(
    [Parameter(Mandatory)][object] $Result,
    [Parameter(Mandatory)][ValidateSet('Passed', 'Failed', 'Skipped')][string] $Name
  )
  $names = $Result.PSObject.Properties.Name
  $countPropName = "$Name`Count"
  if ($names -contains $countPropName) { return [int] $Result.$countPropName }
  if ($names -contains $Name) { return [int] (@($Result.$Name).Count) }
  return 0
}

$testsPassedCount = Get-TestResultCount -Result $testExecutionResults -Name 'Passed'
$testsFailedCount = Get-TestResultCount -Result $testExecutionResults -Name 'Failed'
$testsSkippedCount = Get-TestResultCount -Result $testExecutionResults -Name 'Skipped'
$executionDurationSeconds = [Math]::Round(($testExecutionResults.Duration.TotalSeconds), 2)

# Display comprehensive test execution summary
$summaryTemplate = 'Test Execution Summary: Passed={0} Failed={1} Skipped={2} Duration={3}s'
$testSummaryMessage = $summaryTemplate -f $testsPassedCount, $testsFailedCount, `
  $testsSkippedCount, $executionDurationSeconds

Write-Information $testSummaryMessage

#############################
# EXIT CODE DETERMINATION
#############################

# Return appropriate exit code for CI/CD pipeline integration
if ($testsFailedCount -gt 0) {
  Write-Warning "Test execution completed with $testsFailedCount failed test(s)"
  exit 1
}
else {
  Write-Information 'All tests passed successfully'
  exit 0
}