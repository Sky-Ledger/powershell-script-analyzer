# Test file for PSCustomRule_ErrorActionPreferenceStop rule validation
# Tests scenarios where $ErrorActionPreference = 'Stop' directive is correctly present

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Import required modules for testing
Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'rules/00-SkyLedger.Rules.psm1') -Force -ErrorAction Stop

Describe 'PSCustomRule_ErrorActionPreferenceStop.Present' -Tag 'ErrorActionPreferenceStop','Analyzer' {
  
  # Test: Verify that the rule produces no diagnostics when $ErrorActionPreference = 'Stop' is correctly present
  # Expected behavior: Rule should produce zero diagnostics when the required directive is found with correct value
  # Test scenario: Script contains the proper directive followed by other PowerShell commands
  It 'Produces no diagnostics when directive present' {
    # Arrange: Create a script that includes the required $ErrorActionPreference = 'Stop' directive
    $code = '$ErrorActionPreference = "Stop"`nWrite-Host hi'
    
    # Parse the test code into an Abstract Syntax Tree (AST) for rule analysis
    $tokens=$null;$errors=$null
    $ast=[System.Management.Automation.Language.Parser]::ParseInput($code,[ref]$tokens,[ref]$errors)
    
    # Act: Execute the custom rule against the parsed AST
    $diagnostics = PSCustomRule_ErrorActionPreferenceStop -ScriptBlockAst $ast -Options @{} -Path 'InMemory.ps1'
    
    # Assert: Verify that no diagnostics are produced when the directive is present and correct
    @($diagnostics | Where-Object RuleName -eq 'PSCustomRule_ErrorActionPreferenceStop').Count | Should -Be 0
  }
}