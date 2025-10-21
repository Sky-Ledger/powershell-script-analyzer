# Test file for PSCustomRule_StrictModeVersion rule validation
# Tests scenarios where Set-StrictMode -Version 3.0 directive is completely missing

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Import required modules for testing
Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'rules/00-SkyLedger.Rules.psm1') -Force -ErrorAction Stop

Describe 'PSCustomRule_StrictModeVersion.MissingDirective' -Tag 'StrictModeVersion','Analyzer' {
  
  # Test: Verify that the rule detects missing Set-StrictMode -Version 3.0 directive
  # Expected behavior: Rule should produce exactly one diagnostic when the required directive is completely absent
  # Test scenario: Script contains only variable assignment without any strict mode setting
  It 'Flags missing strict mode directive' {
    # Arrange: Create a simple script that lacks the required Set-StrictMode -Version 3.0 directive
    $code = '$nothing = 2'
    
    # Parse the test code into an Abstract Syntax Tree (AST) for rule analysis
    $tokens=$null;$errors=$null
    $ast=[System.Management.Automation.Language.Parser]::ParseInput($code,[ref]$tokens,[ref]$errors)
    
    # Act: Execute the custom rule against the parsed AST
    $diagnostics = PSCustomRule_StrictModeVersion -ScriptBlockAst $ast -Options @{} -Path 'InMemory.ps1'
    
    # Assert: Verify that exactly one diagnostic is produced by the rule
    $hits = @($diagnostics | Where-Object RuleName -eq 'PSCustomRule_StrictModeVersion')
    $hits.Count | Should -Be 1
    
    # Assert: Verify that the diagnostic message indicates the directive is missing
    $hits[0].Message | Should -Match 'Missing'
  }
}