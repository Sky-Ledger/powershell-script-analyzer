# Test file for PSCustomRule_ErrorActionPreferenceStop rule validation
# Tests scenarios with various whitespace and spacing patterns around the directive

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Import required modules for testing
Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'rules/00-Custom.Rules.psm1') `
  -Force -ErrorAction Stop

Describe 'PSCustomRule_ErrorActionPreferenceStop.Spacing' -Tag 'ErrorActionPreferenceStop', 'Analyzer' {

  # Test: Verify that the rule accepts ErrorActionPreference directive with arbitrary whitespace
  # Expected behavior: Rule should produce no diagnostics regardless of spacing around assignment operator
  # Test scenario: Script contains directive with extra spaces around equals sign and value
  It 'Allows arbitrary spacing around = and value' {
    # Arrange: Create a script with ErrorActionPreference directive containing extra whitespace
    $code = '$ErrorActionPreference    =    "Stop"'

    # Parse the test code into an Abstract Syntax Tree (AST) for rule analysis
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$tokens, [ref]$errors)

    # Act: Execute the custom rule against the parsed AST
    $diagnostics = PSCustomRule_ErrorActionPreferenceStop -ScriptBlockAst $ast -Options @{} -Path 'InMemory.ps1'

    # Assert: Verify that no diagnostics are produced despite unconventional spacing
    @($diagnostics | Where-Object RuleName -EQ 'PSCustomRule_ErrorActionPreferenceStop').Count | Should -Be 0
  }
}