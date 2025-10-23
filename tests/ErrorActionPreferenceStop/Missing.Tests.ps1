# Test file for PSCustomRule_ErrorActionPreferenceStop rule validation
# Tests scenarios where $ErrorActionPreference = 'Stop' directive is completely missing

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Import required modules for testing
Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'rules/00-Custom.Rules.psm1') `
  -Force -ErrorAction Stop

Describe 'PSCustomRule_ErrorActionPreferenceStop.Missing' -Tag 'ErrorActionPreferenceStop', 'Analyzer' {

  # Test: Verify that the rule detects missing $ErrorActionPreference = 'Stop' directive
  # Expected behavior: Rule should produce exactly one diagnostic when the required directive is completely absent
  # Test scenario: Script contains only a Write-Host command without any error action preference setting
  It 'Produces one diagnostic when directive missing' {
    # Arrange: Create a simple script that lacks the required $ErrorActionPreference = 'Stop' directive
    $code = "Write-Host 'hi'"

    # Parse the test code into an Abstract Syntax Tree (AST) for rule analysis
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$tokens, [ref]$errors)

    # Act: Execute the custom rule against the parsed AST
    $diagnostics = PSCustomRule_ErrorActionPreferenceStop -ScriptBlockAst $ast -Options @{} -Path 'InMemory.ps1'

    # Assert: Verify that exactly one diagnostic is produced by the rule
    $hits = @($diagnostics | Where-Object RuleName -EQ 'PSCustomRule_ErrorActionPreferenceStop')
    $hits.Count | Should -Be 1

    # Assert: Verify that the diagnostic message indicates the directive is missing
    $hits[0].Message | Should -Match 'Missing'
  }
}