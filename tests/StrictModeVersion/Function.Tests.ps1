# Test file for PSCustomRule_StrictModeVersion rule validation
# Tests scenarios where Set-StrictMode -Version 3.0 is correctly placed at script root before function definitions

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Import required modules for testing
Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
Import-Module -Name (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'rules/00-SkyLedger.Rules.psm1') -Force -ErrorAction Stop

Describe 'PSCustomRule_StrictModeVersion.FunctionTopLevelDirective' -Tag 'StrictModeVersion','Analyzer' {
  
  # Test: Verify that the rule accepts top-level Set-StrictMode directive in scripts with function definitions
  # Expected behavior: Rule should produce no diagnostics when directive is properly placed at script root
  # Test scenario: Script contains Set-StrictMode -Version 3.0 at root level before function definitions
  It 'Passes when top-level Set-StrictMode precedes function definition' {
    # Arrange: Create a script with proper root-level Set-StrictMode directive followed by function definitions
    $code = @'
Set-StrictMode -Version 3.0
function Invoke-Something {
  $x = 1
}
Invoke-Something
'@
    
    # Parse the test code into an Abstract Syntax Tree (AST) for rule analysis
    $tokens=$null;$errors=$null
    $ast=[System.Management.Automation.Language.Parser]::ParseInput($code,[ref]$tokens,[ref]$errors)
    
    # Act: Execute the custom rule against the parsed AST
    $diagnostics = PSCustomRule_StrictModeVersion -ScriptBlockAst $ast -Options @{} -Path 'InMemory.ps1'
    
    # Assert: Verify that no diagnostics are produced when directive is at proper root level
    $hits = @($diagnostics | Where-Object RuleName -eq 'PSCustomRule_StrictModeVersion')
    $hits.Count | Should -Be 0
  }
}