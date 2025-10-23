# Test file for PSCustomRule_StrictModeVersion rule validation
# Tests scenarios where Set-StrictMode is set to incorrect versions (not 3.x)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Import required modules for testing
Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'rules/00-Custom.Rules.psm1') `
  -Force -ErrorAction Stop

Describe 'PSCustomRule_StrictModeVersion.WrongVersion' -Tag 'StrictModeVersion', 'Analyzer' {

  # Test: Verify that the rule treats incorrect StrictMode versions as missing
  # Expected behavior: Rule should produce one diagnostic when Set-StrictMode is set to non-3.x versions
  # Test scenario: Script sets StrictMode to version 2.0 instead of required 3.0 or higher
  It 'Flags wrong strict mode version' {
    # Arrange: Create a script with Set-StrictMode set to version 2.0 instead of 3.0
    $code = 'Set-StrictMode -Version 2.0; $var = 1'

    # Parse the test code into an Abstract Syntax Tree (AST) for rule analysis
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$tokens, [ref]$errors)

    # Act: Execute the custom rule against the parsed AST
    $diagnostics = PSCustomRule_StrictModeVersion -ScriptBlockAst $ast -Options @{} -Path 'InMemory.ps1'

    # Assert: Verify that exactly one diagnostic is produced for incorrect version
    $hits = @($diagnostics | Where-Object RuleName -EQ 'PSCustomRule_StrictModeVersion')
    $hits.Count | Should -Be 1

    # Assert: Verify that the diagnostic message indicates the directive is missing (wrong version treated as missing)
    $hits[0].Message | Should -Match 'Missing'
  }
}