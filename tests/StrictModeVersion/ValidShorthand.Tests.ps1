# Test file for PSCustomRule_StrictModeVersion rule validation
# Tests scenarios with shorthand Set-StrictMode syntax (positional parameter)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Import required modules for testing
Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'rules/00-SkyLedger.Rules.psm1') -Force -ErrorAction Stop

Describe 'PSCustomRule_StrictModeVersion.ValidShorthand' -Tag 'StrictModeVersion','Analyzer' {
  
  # Test: Verify that the rule accepts shorthand Set-StrictMode syntax with positional parameter
  # Expected behavior: Rule should produce no diagnostics when using positional parameter syntax
  # Test scenario: Script uses Set-StrictMode 3.0 without explicit -Version parameter name
  It 'Passes when shorthand Set-StrictMode 3.0 present' {
    # Arrange: Create a script with Set-StrictMode using positional parameter syntax
    $code = 'Set-StrictMode 3.0'
    
    # Parse the test code into an Abstract Syntax Tree (AST) for rule analysis
    $tokens=$null;$errors=$null
    $ast=[System.Management.Automation.Language.Parser]::ParseInput($code,[ref]$tokens,[ref]$errors)
    
    # Act: Execute the custom rule against the parsed AST
    $diagnostics = PSCustomRule_StrictModeVersion -ScriptBlockAst $ast -Options @{} -Path 'InMemory.ps1'
    
    # Assert: Verify that no diagnostics are produced for shorthand syntax
    @($diagnostics | Where-Object RuleName -eq 'PSCustomRule_StrictModeVersion').Count | Should -Be 0
  }
}