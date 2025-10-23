# Test file for PSCustomRule_ErrorActionPreferenceStop rule validation
# Tests scenarios where $ErrorActionPreference is set to incorrect values (not 'Stop')

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Import required modules for testing
Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'rules/00-Custom.Rules.psm1') `
  -Force -ErrorAction Stop

Describe 'PSCustomRule_ErrorActionPreferenceStop.WrongValue' -Tag 'ErrorActionPreferenceStop', 'Analyzer' {

  # Test: Verify that the rule treats incorrect ErrorActionPreference values as missing
  # Expected behavior: Rule should produce one diagnostic when ErrorActionPreference is set to non-'Stop' values
  # Test scenario: Script sets ErrorActionPreference to 'Continue' instead of required 'Stop'
  It 'Treats non-Stop value as missing' {
    # Arrange: Create a script with ErrorActionPreference set to 'Continue' instead of 'Stop'
    $code = '$ErrorActionPreference = ''Continue''`nWrite-Host hi'

    # Parse the test code into an Abstract Syntax Tree (AST) for rule analysis
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$tokens, [ref]$errors)

    # Act: Execute the custom rule against the parsed AST
    $diagnostics = PSCustomRule_ErrorActionPreferenceStop -ScriptBlockAst $ast -Options @{} -Path 'InMemory.ps1'

    # Assert: Verify that exactly one diagnostic is produced for incorrect value
    $hits = @($diagnostics | Where-Object RuleName -EQ 'PSCustomRule_ErrorActionPreferenceStop')
    $hits.Count | Should -Be 1

    # Assert: Verify that the diagnostic message indicates the directive is missing (wrong value treated as missing)
    $hits[0].Message | Should -Match 'Missing'
  }
}