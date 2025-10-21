# Test file for PSCustomRule_StrictModeVersion rule validation
# Tests scenarios where Set-StrictMode -Version 3.0 directive is correctly present

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Import required modules for testing
Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'rules/00-SkyLedger.Rules.psm1') -Force -ErrorAction Stop

Describe 'PSCustomRule_StrictModeVersion.ValidDirective' -Tag 'StrictModeVersion','Analyzer' {
  
  # Test: Verify that the rule produces no diagnostics when Set-StrictMode -Version 3.0 is correctly present
  # Expected behavior: Rule should produce zero diagnostics when the required directive is found with correct version
  # Test scenario: Script contains the proper Set-StrictMode directive followed by other PowerShell commands
  It 'Passes when Set-StrictMode -Version 3.0 present' {
    # Arrange: Create a script that includes the required Set-StrictMode -Version 3.0 directive
    $code = 'Set-StrictMode -Version 3.0; $var = 1'
    
    # Parse the test code into an Abstract Syntax Tree (AST) for rule analysis
    $tokens=$null;$errors=$null
    $ast=[System.Management.Automation.Language.Parser]::ParseInput($code,[ref]$tokens,[ref]$errors)
    
    # Act: Execute the custom rule against the parsed AST
    $diagnostics = PSCustomRule_StrictModeVersion -ScriptBlockAst $ast -Options @{} -Path 'InMemory.ps1'
    
    # Assert: Verify that no diagnostics are produced when the directive is present and correct
    @($diagnostics | Where-Object RuleName -eq 'PSCustomRule_StrictModeVersion').Count | Should -Be 0
  }
}