# Test file for PSCustomRule_ErrorActionPreferenceStop rule validation
# Tests scenarios where $ErrorActionPreference = 'Stop' is only set inside functions (not at script root)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Import required modules for testing
Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'rules/00-Custom.Rules.psm1') `
  -Force -ErrorAction Stop

Describe 'PSCustomRule_ErrorActionPreferenceStop.FunctionOnly' -Tag 'ErrorActionPreferenceStop', 'Analyzer' {

  # Test: Verify that the rule requires ErrorActionPreference directive at script root, not just inside functions
  # Expected behavior: Rule should produce one diagnostic even when directive exists inside function scope
  # Test scenario: Script defines a function with ErrorActionPreference = 'Stop' but lacks root-level directive
  It 'Requires directive at root even if set in function only' {
    # Arrange: Create a script where ErrorActionPreference is set only inside a function, not at root level
    $code = "function DoStuff { `$ErrorActionPreference = 'Stop' }`nWrite-Host 'x'"

    # Parse the test code into an Abstract Syntax Tree (AST) for rule analysis
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$tokens, [ref]$errors)

    # Act: Execute the custom rule against the parsed AST
    $diagnostics = PSCustomRule_ErrorActionPreferenceStop -ScriptBlockAst $ast -Options @{} -Path 'InMemory.ps1'

    # Assert: Verify that exactly one diagnostic is produced despite function-level directive
    $hits = @($diagnostics | Where-Object RuleName -EQ 'PSCustomRule_ErrorActionPreferenceStop')
    $hits.Count | Should -Be 1

    # Assert: Verify that the diagnostic message indicates the root-level directive is missing
    $hits[0].Message | Should -Match 'Missing'
  }
}