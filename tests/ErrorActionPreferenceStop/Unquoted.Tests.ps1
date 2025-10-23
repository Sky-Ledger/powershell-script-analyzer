# Test file for PSCustomRule_ErrorActionPreferenceStop rule validation
# Tests scenarios where 'Stop' value is used without quotes

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Import required modules for testing
Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'rules/00-Custom.Rules.psm1') `
  -Force -ErrorAction Stop

Describe 'PSCustomRule_ErrorActionPreferenceStop.Unquoted' -Tag 'ErrorActionPreferenceStop', 'Analyzer' {

  # Test: Verify that the rule accepts unquoted 'Stop' keyword as valid value
  # Expected behavior: Rule should produce no diagnostics when Stop is used without quotes
  # Test scenario: Script contains directive with Stop as bare word (PowerShell enum value)
  It 'Accepts unquoted Stop keyword' {
    # Arrange: Create a script with ErrorActionPreference set to unquoted Stop keyword
    $code = '$ErrorActionPreference = Stop'

    # Parse the test code into an Abstract Syntax Tree (AST) for rule analysis
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$tokens, [ref]$errors)

    # Act: Execute the custom rule against the parsed AST
    $diagnostics = PSCustomRule_ErrorActionPreferenceStop -ScriptBlockAst $ast -Options @{} -Path 'InMemory.ps1'

    # Assert: Verify that no diagnostics are produced for unquoted Stop value
    @($diagnostics | Where-Object RuleName -EQ 'PSCustomRule_ErrorActionPreferenceStop').Count | Should -Be 0
  }
}