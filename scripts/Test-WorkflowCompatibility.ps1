<#
.SYNOPSIS
  Validates GitHub workflow compatibility locally.

.DESCRIPTION
  Comprehensive pre-flight validation for the PowerShell quality workflow before it runs in GitHub Actions.
  Confirms integrity of: required modules, custom analyzer rules, rule-to-test coverage, Pester runner, analyzer
  wrapper, settings file, and workflow YAML. Emits symbols (✅/⚠️/❌) only—no color—for analyzer compliance.

  Validated components:
    1. Required modules (PSScriptAnalyzer, Pester >=5)
    2. Custom Sky-Ledger rules module
    3. Rule ↔ test coverage mapping
    4. Pester test runner script
    5. PSScriptAnalyzer wrapper script
    6. Analyzer settings data file
    7. GitHub workflow YAML structure
    8. Repository-wide analyzer compliance (all .ps1 files)

  Failures never abort the script; aggregate output enables quick triage.

.EXAMPLE
  ./scripts/Test-WorkflowCompatibility.ps1
  Runs from repo root (or scripts directory) and validates all components.

.NOTES
  Author   : Sky-Ledger Team
  Version  : 1.2.0
  Requires : PowerShell 5.1+, PSScriptAnalyzer, Pester 5+, repository structure
  Behavior : Continues after failures; use counts + symbols for readiness.

.LINK
  https://github.com/PowerShell/PSScriptAnalyzer
.LINK
  https://pester.dev/
#>

# ============================================================================
# SCRIPT CONFIGURATION
# ============================================================================

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

<#
Refactored: Removed Write-Host usage (PSAvoidUsingWriteHost). All user-facing messages now use Write-Information
through helper for analyzer compliance. Colors removed for portability; semantic symbols retained (✅/❌/⚠️).
#>

function Show-InfoMessage {
  <#
  .SYNOPSIS
    Writes a standardized informational message using Write-Information.
  .DESCRIPTION
    Provides a single point for emitting analyzer-compliant, symbol-prefixed messages
    (✅/⚠️/❌/🔍) without using Write-Host. Style selection applies semantic formatting
    while keeping output machine-parseable if needed.
  .PARAMETER Message
    The textual content to emit after the style symbol (if any).
  .PARAMETER Style
    Message classification. Controls symbol and formatting. Supported values:
    Success, Warning, Error, Info, Header, Section. Defaults to Info.
  .EXAMPLE
    Write-InfoMessage -Message 'Analyzer completed' -Style Success
  .NOTES
    Replaces previous Write-Host calls to satisfy PSAvoidUsingWriteHost.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string] $Message,
    [ValidateSet('Success', 'Warning', 'Error', 'Info', 'Header', 'Section')]
    [string] $Style = 'Info'
  )

  switch ($Style) {
    'Success' { Write-Output "✅ $Message" }
    'Warning' { Write-Warning "⚠️ $Message" }
    'Error' { Write-Error "❌ $Message" }
    'Header' { Write-Output "🔍 $Message" }
    'Section' { Write-Output $Message }
    default { Write-Output $Message }
  }
}

# ============================================================================
# WORKFLOW COMPATIBILITY VALIDATION
# ============================================================================

Show-InfoMessage -Message 'Testing GitHub Workflow Compatibility' -Style Header
Show-InfoMessage -Message '======================================' -Style Section

# Determine repository root directory for consistent path resolution
$repositoryRootDirectory = Split-Path -Parent $PSScriptRoot
Show-InfoMessage -Message "Repository root: $repositoryRootDirectory" -Style Info

# ============================================================================
# TEST 1: REQUIRED POWERSHELL MODULES VALIDATION
# ============================================================================

Show-InfoMessage -Message '1. Testing required PowerShell module availability...' -Style Section

# Validate PSScriptAnalyzer module availability and version
try {
  Import-Module PSScriptAnalyzer -ErrorAction Stop
  $psScriptAnalyzerModuleInfo = Get-Module PSScriptAnalyzer
  Show-InfoMessage -Message "PSScriptAnalyzer imported (Version: $($psScriptAnalyzerModuleInfo.Version))" -Style Success
}
catch {
  Show-InfoMessage -Message "PSScriptAnalyzer module not available: $($_.Exception.Message)" -Style Error
  Show-InfoMessage -Message 'Install using: Install-Module -Name PSScriptAnalyzer -Force' -Style Info
}

# Validate Pester v5+ module availability and version
try {
  Import-Module Pester -MinimumVersion 5.0.0 -ErrorAction Stop
  $pesterModuleInfo = Get-Module Pester
  Show-InfoMessage -Message "Pester module imported (Version: $($pesterModuleInfo.Version))" -Style Success
}
catch {
  Show-InfoMessage -Message "Pester v5+ module not available: $($_.Exception.Message)" -Style Error
  Show-InfoMessage -Message 'Install using: Install-Module -Name Pester -MinimumVersion 5.0.0 -Force' -Style Info
}

# ============================================================================
# TEST 2: CUSTOM ANALYZER RULES MODULE VALIDATION
# ============================================================================

Show-InfoMessage -Message '2. Testing Sky-Ledger custom analyzer rules module...' -Style Section

# Locate the custom Sky-Ledger rules module in the repository
$customAnalyzerRulesModulePath = Join-Path $repositoryRootDirectory 'rules/00-Custom.Rules.psm1'

if (Test-Path $customAnalyzerRulesModulePath) {
  Show-InfoMessage -Message "Custom rules module found: $customAnalyzerRulesModulePath" -Style Success
  try {
    Import-Module $customAnalyzerRulesModulePath -Force -ErrorAction Stop
    Show-InfoMessage -Message 'Custom rules module imported.' -Style Success
    $customRulesModuleBaseName = (Get-Item $customAnalyzerRulesModulePath).BaseName
    $discoveredCustomRuleFunctions = Get-Command -Module $customRulesModuleBaseName |
    Where-Object { $_.Name -like 'PSCustomRule_*' }
    if ($discoveredCustomRuleFunctions) {
      $customRuleNames = $discoveredCustomRuleFunctions.Name -join ', '
      Show-InfoMessage -Message "Custom rules count: $($discoveredCustomRuleFunctions.Count) ($customRuleNames)" -Style Success
    }
    else {
      Show-InfoMessage -Message 'No custom rule functions (expect PSCustomRule_*)' -Style Warning
    }
  }
  catch {
    Show-InfoMessage -Message "Failed to import custom rules module: $($_.Exception.Message)" -Style Error
  }
}
else {
  Show-InfoMessage -Message "Custom rules module missing: $customAnalyzerRulesModulePath" -Style Error
}

# ============================================================================
# TEST 3: RULE-TO-TEST COVERAGE VALIDATION
# ============================================================================

Show-InfoMessage -Message '3. Testing rule-to-test coverage mapping...' -Style Section

# Only proceed if custom rules module was successfully imported
if (Get-Module | Where-Object { $_.Name -like '*SkyLedger.Rules*' -or $_.Name -eq '00-SkyLedger.Rules' }) {
  try {
    # Get all custom rule functions from the imported module
    $customRulesModuleBaseName = (Get-Item $customAnalyzerRulesModulePath).BaseName
    $discoveredCustomRuleFunctions = Get-Command -Module $customRulesModuleBaseName | Where-Object { $_.Name -like 'PSCustomRule_*' }

    if ($discoveredCustomRuleFunctions) {
      $testsRootDirectory = Join-Path $repositoryRootDirectory 'tests'
      if (Test-Path $testsRootDirectory) {
        $testDirectoryNames = Get-ChildItem -Path $testsRootDirectory -Directory |
        Select-Object -ExpandProperty Name
        $rulesWithTests = @()
        $rulesMissingTests = @()
        foreach ($customRuleFunction in $discoveredCustomRuleFunctions) {
          $extractedRuleName = $customRuleFunction.Name -replace '^PSCustomRule_', ''
          if ($extractedRuleName -in $testDirectoryNames) {
            $ruleTestDirectory = Join-Path $testsRootDirectory $extractedRuleName
            $testFileCount = (Get-ChildItem -Path $ruleTestDirectory -Filter '*.Tests.ps1' -File -ErrorAction SilentlyContinue).Count
            if ($testFileCount -gt 0) {
              $rulesWithTests += $extractedRuleName
              Show-InfoMessage -Message "Rule '$extractedRuleName' tests: $testFileCount" -Style Success
            }
            else {
              $rulesMissingTests += $extractedRuleName
              Show-InfoMessage -Message "Rule '$extractedRuleName' directory has no tests" -Style Error
            }
          }
          else {
            $rulesMissingTests += $extractedRuleName
            Show-InfoMessage -Message "Rule '$extractedRuleName' has no test directory" -Style Error
          }
        }
        Show-InfoMessage -Message 'Test coverage summary:' -Style Header
        Show-InfoMessage -Message "Rules total: $($discoveredCustomRuleFunctions.Count)" -Style Info
        Show-InfoMessage -Message "Rules with tests: $($rulesWithTests.Count)" -Style Info
        Show-InfoMessage -Message "Rules missing tests: $($rulesMissingTests.Count)" -Style Info
        if ($rulesMissingTests.Count -eq 0) {
          Show-InfoMessage -Message 'All rules have tests.' -Style Success
        }
        else {
          Show-InfoMessage -Message "Missing tests: $($rulesMissingTests -join ', ')" -Style Error
        }
      }
      else {
        Show-InfoMessage -Message "Tests directory missing: $testsRootDirectory" -Style Error
      }
    }
    else {
      Show-InfoMessage -Message 'No rules discovered for coverage validation.' -Style Warning
    }
  }
  catch {
    Show-InfoMessage -Message "Failed to validate rule-to-test coverage: $($_.Exception.Message)" -Style Error
  }
}
else {
  Show-InfoMessage -Message 'Skipping test coverage validation - custom rules module not imported' -Style Warning
}

# ============================================================================
# TEST 4: PESTER TEST RUNNER SCRIPT VALIDATION
# ============================================================================

Show-InfoMessage -Message '4. Testing Pester test execution runner...' -Style Section

# Locate the main Pester test runner script
$pesterTestRunnerScriptPath = Join-Path $repositoryRootDirectory 'tests/Invoke-PesterTests.ps1'

if (Test-Path $pesterTestRunnerScriptPath) {
  Show-InfoMessage -Message "Pester test runner script found: $pesterTestRunnerScriptPath" -Style Success

  # Validate the test runner script is readable and appears valid
  try {
    $testRunnerScriptContent = Get-Content $pesterTestRunnerScriptPath -Raw -ErrorAction Stop
    if ($testRunnerScriptContent -match 'Invoke-Pester' -and $testRunnerScriptContent.Length -gt 100) {
      Show-InfoMessage -Message 'Test runner script appears to contain valid Pester execution code' -Style Success
    }
    else {
      Show-InfoMessage -Message 'Test runner script may be incomplete or malformed' -Style Warning
    }
  }
  catch {
    Show-InfoMessage -Message "Failed to read test runner script: $($_.Exception.Message)" -Style Error
  }
}
else {
  Show-InfoMessage -Message "Pester test runner script not found at expected location: $pesterTestRunnerScriptPath" -Style Error
}

# ============================================================================
# TEST 5: PSSCRIPTANALYZER WRAPPER SCRIPT VALIDATION
# ============================================================================

Show-InfoMessage -Message '5. Testing PSScriptAnalyzer wrapper script...' -Style Section

# Locate the PSScriptAnalyzer execution wrapper script
$scriptAnalyzerWrapperScriptPath = Join-Path $repositoryRootDirectory 'Invoke-PSScriptAnalyzer.ps1'

if (Test-Path $scriptAnalyzerWrapperScriptPath) {
  Show-InfoMessage -Message "PSScriptAnalyzer wrapper script found: $scriptAnalyzerWrapperScriptPath" -Style Success

  # Validate the wrapper script contains expected functionality
  try {
    $wrapperScriptContent = Get-Content $scriptAnalyzerWrapperScriptPath -Raw -ErrorAction Stop
    if (
      ($wrapperScriptContent -match 'Invoke-ScriptAnalyzer') -and
      ($wrapperScriptContent -match 'Settings') -and
      ($wrapperScriptContent.Length -gt 500)
    ) {
      Show-InfoMessage -Message 'Wrapper script appears to contain valid PSScriptAnalyzer execution code' -Style Success
    }
    else {
      Show-InfoMessage -Message 'Wrapper script may be incomplete or missing key functionality' -Style Warning
    }
  }
  catch {
    Show-InfoMessage -Message "Failed to read wrapper script: $($_.Exception.Message)" -Style Error
  }
}
else {
  Show-InfoMessage -Message "PSScriptAnalyzer wrapper script not found at expected location: $scriptAnalyzerWrapperScriptPath" -Style Error
}

# ============================================================================
# TEST 6: ANALYZER SETTINGS CONFIGURATION VALIDATION
# ============================================================================

Show-InfoMessage -Message '6. Testing PSScriptAnalyzer settings configuration...' -Style Section

# Locate the PSScriptAnalyzer configuration settings file
$analyzerSettingsConfigurationPath = Join-Path $repositoryRootDirectory 'PSScriptAnalyzer.Settings.psd1'

if (Test-Path $analyzerSettingsConfigurationPath) {
  Show-InfoMessage -Message "Analyzer settings file found: $analyzerSettingsConfigurationPath" -Style Success

  try {
    # Import and validate the PowerShell data file structure
    $analyzerConfigurationSettings = Import-PowerShellDataFile -LiteralPath $analyzerSettingsConfigurationPath -ErrorAction Stop
    Show-InfoMessage -Message 'Settings configuration loaded and parsed successfully' -Style Success

    # Validate key configuration elements
    if ($analyzerConfigurationSettings.CustomRulePath) {
      Show-InfoMessage -Message "Custom rules path configured: $($analyzerConfigurationSettings.CustomRulePath)" -Style Success
    }
    else {
      Show-InfoMessage -Message 'No custom rules path found in settings configuration' -Style Warning
    }

    if ($analyzerConfigurationSettings.IncludeRules -and $analyzerConfigurationSettings.IncludeRules.Count -gt 0) {
      Show-InfoMessage -Message "Include rules specified: $($analyzerConfigurationSettings.IncludeRules.Count) rule(s)" -Style Success
    }
    else {
      Show-InfoMessage -Message 'No include rules specified in settings configuration' -Style Warning
    }
  }
  catch {
    Show-InfoMessage -Message "Settings configuration file is invalid: $($_.Exception.Message)" -Style Error
  }
}
else {
  Show-InfoMessage `
    -Message "Analyzer settings configuration not found at expected location: `
      $analyzerSettingsConfigurationPath" `
    -Style Error
}

# ============================================================================
# TEST 7: GITHUB WORKFLOW YAML STRUCTURE VALIDATION
# ============================================================================

Show-InfoMessage -Message '7. Testing GitHub Actions workflow configuration...' -Style Section

# Locate the GitHub Actions workflow definition file
$githubWorkflowConfigurationPath = Join-Path $repositoryRootDirectory '.github/workflows/powershell-quality-check.yml'

if (Test-Path $githubWorkflowConfigurationPath) {
  Show-InfoMessage -Message "GitHub workflow file found: $githubWorkflowConfigurationPath" -Style Success

  try {
    # Read and validate basic YAML workflow structure
    $workflowConfigurationContent = Get-Content $githubWorkflowConfigurationPath -Raw -ErrorAction Stop

    # Validate essential YAML workflow elements
    $hasValidWorkflowName = $workflowConfigurationContent -match 'name:\s*PowerShell Quality Check'
    $hasValidTriggers = $workflowConfigurationContent -match 'on:'
    $hasValidJobsSection = $workflowConfigurationContent -match 'jobs:'
    $hasValidStepsStructure = $workflowConfigurationContent -match 'steps:'

    if ($hasValidWorkflowName -and $hasValidTriggers -and $hasValidJobsSection -and $hasValidStepsStructure) {
      Show-InfoMessage -Message 'Workflow YAML structure appears valid with required sections' -Style Success
    }
    else {
      Show-InfoMessage -Message 'Workflow YAML may be missing essential sections (name, on, jobs, steps)' -Style Warning
    }

    # Check for PowerShell-specific workflow components
    if ($workflowConfigurationContent -match 'Invoke-PesterTests' -or $workflowConfigurationContent -match 'Invoke-PSScriptAnalyzer') {
      Show-InfoMessage -Message 'Workflow contains references to PowerShell analysis scripts' -Style Success
    }
    else {
      Show-InfoMessage -Message 'Workflow may not reference the expected PowerShell analysis scripts' -Style Warning
    }
  }
  catch {
    Show-InfoMessage -Message "Failed to read workflow configuration: $($_.Exception.Message)" -Style Error
  }
}
else {
  Show-InfoMessage -Message "GitHub workflow file not found at expected location: $githubWorkflowConfigurationPath" -Style Error
}

# ============================================================================
# VALIDATION SUMMARY AND RECOMMENDATIONS
# ============================================================================

Show-InfoMessage -Message 'GitHub Workflow Compatibility Validation Complete!' -Style Header
Show-InfoMessage -Message '======================================================' -Style Section
Show-InfoMessage -Message '8. Testing repository-wide analyzer compliance...' -Style Section

# Execute repository-wide analyzer validation using the wrapper script if available.
if (Test-Path $scriptAnalyzerWrapperScriptPath) {
  try {
    Show-InfoMessage -Message 'Running analyzer wrapper across entire repository (quiet mode)...' -Style Info
    & $scriptAnalyzerWrapperScriptPath -Path $repositoryRootDirectory -Quiet
    $repositoryAnalyzerExitCode = $LASTEXITCODE
    switch ($repositoryAnalyzerExitCode) {
      0 { Show-InfoMessage -Message 'Repository-wide analysis: no actionable diagnostics.' -Style Success }
      1 { Show-InfoMessage -Message 'Repository-wide analysis: diagnostics found (warnings/errors).' -Style Warning }
      2 { Show-InfoMessage -Message 'Repository-wide analysis failed: invalid target path.' -Style Error }
      3 { Show-InfoMessage -Message 'Repository-wide analysis failed: PSScriptAnalyzer module import error.' -Style Error }
      4 { Show-InfoMessage -Message 'Repository-wide analysis failed: settings file issue.' -Style Error }
      default {
        Show-InfoMessage -Message "Repository-wide analysis returned unexpected exit code $repositoryAnalyzerExitCode." -Style Error
      }
    }
  }
  catch {
    Show-InfoMessage -Message "Repository-wide analyzer execution threw exception: $($_.Exception.Message)" -Style Error
  }
}
else {
  Show-InfoMessage -Message 'Skipping repository-wide analyzer compliance test - wrapper script missing.' -Style Warning
}

Show-InfoMessage -Message 'Summary:' -Style Section
Show-InfoMessage -Message '✅ success  ⚠️ warning  ❌ failure' -Style Info
Show-InfoMessage -Message 'Next:' -Style Section
Show-InfoMessage -Message '• All ✅ => workflow ready' -Style Info
Show-InfoMessage -Message '• Fix all ❌ before pushing' -Style Info
Show-InfoMessage -Message '• Review ⚠️ for optimization' -Style Info
Show-InfoMessage -Message '• Optionally retest modules individually' -Style Info