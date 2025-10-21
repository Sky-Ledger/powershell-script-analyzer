<#
.SYNOPSIS
    Validates GitHub workflow compatibility by testing all required components in the local environment.

.DESCRIPTION
    This script performs comprehensive validation of the PowerShell Script Analyzer workflow
    components to ensure they function correctly before deployment to GitHub Actions. It tests
    module availability, custom rules, test runners, configuration files, and workflow structure.

    The script validates six critical components:
    1. Required PowerShell modules (PSScriptAnalyzer and Pester v5+)
    2. Custom Sky-Ledger analyzer rules module
    3. Pester test runner script
    4. PSScriptAnalyzer wrapper script
    5. Analyzer settings configuration file
    6. GitHub workflow YAML structure

    Each test provides clear pass/fail indicators and detailed error messages to help
    diagnose configuration issues before GitHub Actions execution.

.PARAMETER None
    This script does not accept any parameters.

.EXAMPLE
    .\scripts\Test-WorkflowCompatibility.ps1
    
    Runs from the repository root directory and validates all workflow components.
    Displays colored output indicating the status of each validation test.

.EXAMPLE
    .\Test-WorkflowCompatibility.ps1
    
    Runs from within the scripts directory and validates all workflow components
    using relative paths to the repository root.

.NOTES
    Author: Sky-Ledger Team
    Version: 1.1.0
    
    Requirements:
    - PowerShell 5.1 or later
    - PSScriptAnalyzer module
    - Pester v5.0.0 or later
    - Access to repository directory structure
    
    Exit Behavior:
    - Script completes regardless of test results
    - Individual test failures are reported but do not halt execution
    - Use visual indicators (✅/❌/⚠️) to assess overall compatibility

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

# ============================================================================
# WORKFLOW COMPATIBILITY VALIDATION
# ============================================================================

Write-Host "🔍 Testing GitHub Workflow Compatibility" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Determine repository root directory for consistent path resolution
$repositoryRootDirectory = Split-Path -Parent $PSScriptRoot
Write-Host "Repository root: $repositoryRootDirectory" -ForegroundColor DarkGray

# ============================================================================
# TEST 1: REQUIRED POWERSHELL MODULES VALIDATION
# ============================================================================

Write-Host "`n1. Testing required PowerShell module availability..." -ForegroundColor Yellow

# Validate PSScriptAnalyzer module availability and version
try {
    Import-Module PSScriptAnalyzer -ErrorAction Stop
    $psScriptAnalyzerModuleInfo = Get-Module PSScriptAnalyzer
    Write-Host "   ✅ PSScriptAnalyzer module imported successfully (Version: $($psScriptAnalyzerModuleInfo.Version))" -ForegroundColor Green
} catch {
    Write-Host "   ❌ PSScriptAnalyzer module not available: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "      Install using: Install-Module -Name PSScriptAnalyzer -Force" -ForegroundColor DarkGray
}

# Validate Pester v5+ module availability and version
try {
    Import-Module Pester -MinimumVersion 5.0.0 -ErrorAction Stop
    $pesterModuleInfo = Get-Module Pester
    Write-Host "   ✅ Pester v5+ module imported successfully (Version: $($pesterModuleInfo.Version))" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Pester v5+ module not available: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "      Install using: Install-Module -Name Pester -MinimumVersion 5.0.0 -Force" -ForegroundColor DarkGray
}

# ============================================================================
# TEST 2: CUSTOM ANALYZER RULES MODULE VALIDATION
# ============================================================================

Write-Host "`n2. Testing Sky-Ledger custom analyzer rules module..." -ForegroundColor Yellow

# Locate the custom Sky-Ledger rules module in the repository
$customAnalyzerRulesModulePath = Join-Path $repositoryRootDirectory 'rules/00-SkyLedger.Rules.psm1'

if (Test-Path $customAnalyzerRulesModulePath) {
    Write-Host "   ✅ Custom rules module file found: $customAnalyzerRulesModulePath" -ForegroundColor Green
    
    try {
        # Import the custom rules module with force to refresh any cached version
        Import-Module $customAnalyzerRulesModulePath -Force -ErrorAction Stop
        Write-Host "   ✅ Sky-Ledger custom rules module imported successfully" -ForegroundColor Green
        
        # Discover and validate custom analyzer rules functions
        $customRulesModuleBaseName = (Get-Item $customAnalyzerRulesModulePath).BaseName
        $discoveredCustomRuleFunctions = Get-Command -Module $customRulesModuleBaseName | Where-Object { $_.Name -like 'PSCustomRule_*' }
        
        if ($discoveredCustomRuleFunctions) {
            $customRuleNames = $discoveredCustomRuleFunctions.Name -join ', '
            Write-Host "   ✅ Found $($discoveredCustomRuleFunctions.Count) custom analyzer rules: $customRuleNames" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  No custom rules functions found in module (expected functions matching 'PSCustomRule_*')" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   ❌ Failed to import custom rules module: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "   ❌ Custom rules module not found at expected location: $customAnalyzerRulesModulePath" -ForegroundColor Red
}

# ============================================================================
# TEST 3: PESTER TEST RUNNER SCRIPT VALIDATION
# ============================================================================

Write-Host "`n3. Testing Pester test execution runner..." -ForegroundColor Yellow

# Locate the main Pester test runner script
$pesterTestRunnerScriptPath = Join-Path $repositoryRootDirectory 'tests/Invoke-PesterTests.ps1'

if (Test-Path $pesterTestRunnerScriptPath) {
    Write-Host "   ✅ Pester test runner script found: $pesterTestRunnerScriptPath" -ForegroundColor Green
    
    # Validate the test runner script is readable and appears valid
    try {
        $testRunnerScriptContent = Get-Content $pesterTestRunnerScriptPath -Raw -ErrorAction Stop
        if ($testRunnerScriptContent -match 'Invoke-Pester' -and $testRunnerScriptContent.Length -gt 100) {
            Write-Host "   ✅ Test runner script appears to contain valid Pester execution code" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Test runner script may be incomplete or malformed" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   ❌ Failed to read test runner script: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "   ❌ Pester test runner script not found at expected location: $pesterTestRunnerScriptPath" -ForegroundColor Red
}

# ============================================================================
# TEST 4: PSSCRIPTANALYZER WRAPPER SCRIPT VALIDATION
# ============================================================================

Write-Host "`n4. Testing PSScriptAnalyzer wrapper script..." -ForegroundColor Yellow

# Locate the PSScriptAnalyzer execution wrapper script
$scriptAnalyzerWrapperScriptPath = Join-Path $repositoryRootDirectory 'Invoke-PSScriptAnalyzer.ps1'

if (Test-Path $scriptAnalyzerWrapperScriptPath) {
    Write-Host "   ✅ PSScriptAnalyzer wrapper script found: $scriptAnalyzerWrapperScriptPath" -ForegroundColor Green
    
    # Validate the wrapper script contains expected functionality
    try {
        $wrapperScriptContent = Get-Content $scriptAnalyzerWrapperScriptPath -Raw -ErrorAction Stop
        if ($wrapperScriptContent -match 'Invoke-ScriptAnalyzer' -and $wrapperScriptContent -match 'Settings' -and $wrapperScriptContent.Length -gt 500) {
            Write-Host "   ✅ Wrapper script appears to contain valid PSScriptAnalyzer execution code" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Wrapper script may be incomplete or missing key functionality" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   ❌ Failed to read wrapper script: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "   ❌ PSScriptAnalyzer wrapper script not found at expected location: $scriptAnalyzerWrapperScriptPath" -ForegroundColor Red
}

# ============================================================================
# TEST 5: ANALYZER SETTINGS CONFIGURATION VALIDATION
# ============================================================================

Write-Host "`n5. Testing PSScriptAnalyzer settings configuration..." -ForegroundColor Yellow

# Locate the PSScriptAnalyzer configuration settings file
$analyzerSettingsConfigurationPath = Join-Path $repositoryRootDirectory 'PSScriptAnalyzer.Settings.psd1'

if (Test-Path $analyzerSettingsConfigurationPath) {
    Write-Host "   ✅ Analyzer settings file found: $analyzerSettingsConfigurationPath" -ForegroundColor Green
    
    try {
        # Import and validate the PowerShell data file structure
        $analyzerConfigurationSettings = Import-PowerShellDataFile -LiteralPath $analyzerSettingsConfigurationPath -ErrorAction Stop
        Write-Host "   ✅ Settings configuration loaded and parsed successfully" -ForegroundColor Green
        
        # Validate key configuration elements
        if ($analyzerConfigurationSettings.CustomRulePath) {
            Write-Host "   ✅ Custom rules path configured: $($analyzerConfigurationSettings.CustomRulePath)" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  No custom rules path found in settings configuration" -ForegroundColor Yellow
        }
        
        if ($analyzerConfigurationSettings.IncludeRules -and $analyzerConfigurationSettings.IncludeRules.Count -gt 0) {
            Write-Host "   ✅ Include rules specified: $($analyzerConfigurationSettings.IncludeRules.Count) rule(s)" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  No include rules specified in settings configuration" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "   ❌ Settings configuration file is invalid: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "   ❌ Analyzer settings configuration not found at expected location: $analyzerSettingsConfigurationPath" -ForegroundColor Red
}

# ============================================================================
# TEST 6: GITHUB WORKFLOW YAML STRUCTURE VALIDATION
# ============================================================================

Write-Host "`n6. Testing GitHub Actions workflow configuration..." -ForegroundColor Yellow

# Locate the GitHub Actions workflow definition file
$githubWorkflowConfigurationPath = Join-Path $repositoryRootDirectory '.github/workflows/powershell-quality-check.yml'

if (Test-Path $githubWorkflowConfigurationPath) {
    Write-Host "   ✅ GitHub workflow file found: $githubWorkflowConfigurationPath" -ForegroundColor Green
    
    try {
        # Read and validate basic YAML workflow structure
        $workflowConfigurationContent = Get-Content $githubWorkflowConfigurationPath -Raw -ErrorAction Stop
        
        # Validate essential YAML workflow elements
        $hasValidWorkflowName = $workflowConfigurationContent -match 'name:\s*PowerShell Quality Check'
        $hasValidTriggers = $workflowConfigurationContent -match 'on:'
        $hasValidJobsSection = $workflowConfigurationContent -match 'jobs:'
        $hasValidStepsStructure = $workflowConfigurationContent -match 'steps:'
        
        if ($hasValidWorkflowName -and $hasValidTriggers -and $hasValidJobsSection -and $hasValidStepsStructure) {
            Write-Host "   ✅ Workflow YAML structure appears valid with required sections" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Workflow YAML may be missing essential sections (name, on, jobs, steps)" -ForegroundColor Yellow
        }
        
        # Check for PowerShell-specific workflow components
        if ($workflowConfigurationContent -match 'Invoke-PesterTests' -or $workflowConfigurationContent -match 'Invoke-PSScriptAnalyzer') {
            Write-Host "   ✅ Workflow contains references to PowerShell analysis scripts" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Workflow may not reference the expected PowerShell analysis scripts" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "   ❌ Failed to read workflow configuration: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "   ❌ GitHub workflow file not found at expected location: $githubWorkflowConfigurationPath" -ForegroundColor Red
}

# ============================================================================
# VALIDATION SUMMARY AND RECOMMENDATIONS
# ============================================================================

Write-Host "`n🎯 GitHub Workflow Compatibility Validation Complete!" -ForegroundColor Magenta
Write-Host "======================================================" -ForegroundColor Magenta

Write-Host "`nValidation Summary:" -ForegroundColor White
Write-Host "  ✅ = Component validated successfully" -ForegroundColor Green
Write-Host "  ⚠️  = Component found but may have issues" -ForegroundColor Yellow
Write-Host "  ❌ = Component missing or failed validation" -ForegroundColor Red

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  • If all items show ✅, the GitHub workflow should execute successfully" -ForegroundColor White
Write-Host "  • Address any ❌ issues before pushing to trigger GitHub Actions" -ForegroundColor White
Write-Host "  • Review ⚠️  warnings to ensure optimal workflow performance" -ForegroundColor White
Write-Host "  • Run individual components locally to verify functionality" -ForegroundColor White