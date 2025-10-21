# Test file for PSCustomRule_StrictModeVersion rule validation
# Tests scenarios where Set-StrictMode -Version 3.0 is only set inside functions (not at script root)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Import required modules for testing
Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'rules/00-SkyLedger.Rules.psm1') -Force -ErrorAction Stop

Describe 'PSCustomRule_StrictModeVersion.FunctionOnly' -Tag 'StrictModeVersion','Analyzer' {
  
  # Test: Verify that the rule requires Set-StrictMode directive at script root, not just inside functions
  # Expected behavior: Rule should produce one diagnostic even when directive exists inside function scope
  # Test scenario: Script defines a function with Set-StrictMode -Version 3.0 but lacks root-level directive
  It 'Flags missing directive when only inside function' {
    # Arrange: Create a script where Set-StrictMode is set only inside a function, not at root level
    $code = @'
function Invoke-Something {
  Set-StrictMode -Version 3.0
  $x = 1
}
Invoke-Something
'@
    
    # Parse the test code into an Abstract Syntax Tree (AST) for rule analysis
    $tokens=$null;$errors=$null
    $ast=[System.Management.Automation.Language.Parser]::ParseInput($code,[ref]$tokens,[ref]$errors)
    
    # Act: Execute the custom rule against the parsed AST
    $diagnostics = PSCustomRule_StrictModeVersion -ScriptBlockAst $ast -Options @{} -Path 'InMemory.ps1'
    
    # Assert: Verify that exactly one diagnostic is produced despite function-level directive
    $hits = @($diagnostics | Where-Object RuleName -eq 'PSCustomRule_StrictModeVersion')
    $hits.Count | Should -Be 1
    
    # Assert: Verify that the diagnostic message indicates the root-level directive is missing
    $hits[0].Message | Should -Match 'Missing'
  }
}