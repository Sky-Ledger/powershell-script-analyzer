# Test file for PSCustomRule_ErrorActionPreferenceStop rule validation
# Tests scenarios where directive is correctly placed before other script code

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Import required modules for testing
Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'rules/00-Custom.Rules.psm1') `
  -Force -ErrorAction Stop

Describe 'PSCustomRule_ErrorActionPreferenceStop.PostCode' -Tag 'ErrorActionPreferenceStop', 'Analyzer' {

  # Test: Verify that the rule accepts directive when placed before other script code
  # Expected behavior: Rule should produce no diagnostics when directive appears at start of multi-line script
  # Test scenario: Script contains directive followed by multiple lines of PowerShell commands
  It 'Allows directive before other code' {
    # Arrange: Create a multi-line script with ErrorActionPreference directive followed by other commands
    $code = '$ErrorActionPreference = "Stop"`nWrite-Host "after"`nGet-Date | Out-Null'

    # Parse the test code into an Abstract Syntax Tree (AST) for rule analysis
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$tokens, [ref]$errors)

    # Act: Execute the custom rule against the parsed AST
    $diagnostics = PSCustomRule_ErrorActionPreferenceStop -ScriptBlockAst $ast -Options @{} -Path 'InMemory.ps1'

    # Assert: Verify that no diagnostics are produced when directive precedes other code
    @($diagnostics | Where-Object RuleName -EQ 'PSCustomRule_ErrorActionPreferenceStop').Count | Should -Be 0
  }
}